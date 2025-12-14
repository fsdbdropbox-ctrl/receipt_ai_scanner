import Stripe from 'stripe';
import { setUserPlan } from '../services/user-service.js';
import { isEventProcessed, markEventProcessed } from '../middleware/webhookIdempotency.js';

// STRIPE_SECRET_KEY is validated in app.js
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export async function stripeWebhookRoute(fastify) {
  // Register content type parser for raw body (Stripe webhooks)
  fastify.addContentTypeParser('application/json', { parseAs: 'buffer' }, (req, body, done) => {
    req.rawBody = body;
    done(null, body);
  });

  fastify.post('/api/stripe-webhook', async (request, reply) => {
    const sig = request.headers['stripe-signature'];
    const buf = request.rawBody;

    // Validate required inputs
    if (!sig || !buf) {
      fastify.log.warn('Webhook: Missing signature or body');
      return reply.code(400).send({ error: 'Missing signature or body' });
    }

    if (!process.env.STRIPE_WEBHOOK_SECRET) {
      fastify.log.error('Webhook: STRIPE_WEBHOOK_SECRET not configured');
      return reply.code(500).send({ error: 'Webhook not configured' });
    }

    // Verify webhook signature
    let event;
    try {
      event = stripe.webhooks.constructEvent(
        buf,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET,
      );
    } catch (err) {
      fastify.log.error({ err: err.message }, 'Webhook signature verification failed');
      return reply.code(400).send({ error: 'Invalid signature' });
    }

    // Log event (sanitized)
    fastify.log.info({
      eventId: event.id,
      type: event.type,
    }, 'Webhook event received');

    // Check idempotency - skip if already processed
    try {
      if (await isEventProcessed(event.id)) {
        fastify.log.info({ eventId: event.id }, 'Webhook event already processed, skipping');
        return reply.send({ received: true, skipped: true });
      }
    } catch (err) {
      // If Redis fails, continue processing (prefer occasional duplicate over dropped events)
      fastify.log.warn({ err: err.message }, 'Idempotency check failed, continuing');
    }

    try {
      let processed = false;

      // Handle subscription events
      if (event.type === 'customer.subscription.created' ||
        event.type === 'customer.subscription.updated') {
        const subscription = event.data.object;
        const installId = subscription.metadata?.installId;
        const status = subscription.status;

        if (installId) {
          // Active states that grant premium access
          if (status === 'active' || status === 'trialing') {
            await setUserPlan(installId, true);
            fastify.log.info({
              installId: installId.substring(0, 8) + '...',
              status,
            }, 'Premium activated');
            processed = true;
          }
          // States that revoke premium access
          else if (['past_due', 'unpaid', 'canceled', 'incomplete_expired'].includes(status)) {
            await setUserPlan(installId, false);
            fastify.log.info({
              installId: installId.substring(0, 8) + '...',
              status,
            }, 'Premium deactivated');
            processed = true;
          }
          // incomplete - waiting for payment, don't change status yet
        }
      }

      // Handle subscription deletion
      else if (event.type === 'customer.subscription.deleted') {
        const subscription = event.data.object;
        const installId = subscription.metadata?.installId;

        if (installId) {
          await setUserPlan(installId, false);
          fastify.log.info({
            installId: installId.substring(0, 8) + '...',
          }, 'Premium deactivated (subscription deleted)');
          processed = true;
        }
      }

      // Handle checkout completion as fallback
      else if (event.type === 'checkout.session.completed') {
        const session = event.data.object;
        const installId = session.client_reference_id;

        if (installId && session.mode === 'subscription' && session.subscription) {
          try {
            const subscription = await stripe.subscriptions.retrieve(session.subscription);
            if (subscription.status === 'active' || subscription.status === 'trialing') {
              await setUserPlan(installId, true);
              fastify.log.info({
                installId: installId.substring(0, 8) + '...',
              }, 'Premium activated via checkout');
              processed = true;
            }
          } catch (err) {
            fastify.log.error({ err: err.message }, 'Error retrieving subscription');
          }
        }
      }

      // Handle payment failures
      else if (event.type === 'invoice.payment_failed') {
        const invoice = event.data.object;
        // Log for monitoring, but don't immediately revoke
        // (subscription.updated will handle status changes)
        fastify.log.warn({
          customerId: invoice.customer,
          attemptCount: invoice.attempt_count,
        }, 'Payment failed');
      }

      // Mark event as processed
      try {
        await markEventProcessed(event.id, {
          type: event.type,
          processed,
        });
      } catch (err) {
        fastify.log.warn({ err: err.message }, 'Failed to mark event as processed');
      }

      return reply.send({ received: true, processed });

    } catch (error) {
      fastify.log.error({ err: error.message }, 'Webhook processing error');
      // Return 200 to prevent Stripe retries for processing errors
      // (we've received and logged the event)
      return reply.send({ received: true, error: 'Processing error logged' });
    }
  });
}
