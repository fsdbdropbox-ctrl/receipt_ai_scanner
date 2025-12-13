import Stripe from 'stripe';
import { setUserPlan } from '../services/user-service.js';

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error('STRIPE_SECRET_KEY is required');
}

if (!process.env.STRIPE_WEBHOOK_SECRET) {
  throw new Error('STRIPE_WEBHOOK_SECRET is required');
}

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export async function stripeWebhookRoute(fastify) {
  // Register content type parser for raw body (Stripe webhooks)
  fastify.addContentTypeParser('application/json', { parseAs: 'buffer' }, (req, body, done) => {
    req.rawBody = body;
    done(null, body);
  });

  fastify.post('/api/stripe-webhook', async (request, reply) => {
    const sig = request.headers['stripe-signature'];
    const buf = request.rawBody; // Buffer

    if (!sig || !buf) {
      return reply.code(400).send({ error: 'Missing signature or body' });
    }

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        buf,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET,
      );
    } catch (err) {
      return reply.code(400).send({ error: `Webhook signature verification failed: ${err.message}` });
    }

    try {
      // Handle subscription events (active, trialing = premium)
      if (event.type === 'customer.subscription.created' || event.type === 'customer.subscription.updated') {
        const subscription = event.data.object;
        const installId = subscription.metadata?.installId;

        // Activate premium if subscription is active or trialing (trial period)
        if (installId && (subscription.status === 'active' || subscription.status === 'trialing')) {
          await setUserPlan(installId, true);
          fastify.log.info(`Premium activated for installId: ${installId} (status: ${subscription.status})`);
        } else if (installId && (subscription.status === 'past_due' || subscription.status === 'unpaid' || subscription.status === 'canceled')) {
          // Deactivate premium if subscription is past_due, unpaid, or canceled
          await setUserPlan(installId, false);
          fastify.log.info(`Premium deactivated for installId: ${installId} (status: ${subscription.status})`);
        }
      }
      // Fallback: Handle checkout completion (in case subscription metadata is missing)
      else if (event.type === 'checkout.session.completed') {
        const session = event.data.object;
        const installId = session.client_reference_id;

        // Only activate if we have the installId and can't rely on subscription.created
        if (installId && session.mode === 'subscription') {
          // Try to get subscription from session
          if (session.subscription) {
            try {
              const subscription = await stripe.subscriptions.retrieve(session.subscription);
              if (subscription.status === 'active' || subscription.status === 'trialing') {
                await setUserPlan(installId, true);
                fastify.log.info(`Premium activated via checkout.session.completed for installId: ${installId}`);
              }
            } catch (err) {
              fastify.log.error(`Error retrieving subscription: ${err.message}`);
              // Fallback: activate premium anyway (trial will be handled by subscription.created)
              await setUserPlan(installId, true);
            }
          } else {
            // No subscription yet, activate anyway (will be updated by subscription.created)
            await setUserPlan(installId, true);
          }
        }
      }
      // Handle subscription cancellation/deletion
      else if (event.type === 'customer.subscription.deleted') {
        const subscription = event.data.object;
        const installId = subscription.metadata?.installId;

        if (installId) {
          await setUserPlan(installId, false);
          fastify.log.info(`Premium deactivated for installId: ${installId} (subscription deleted)`);
        }
      }

      return reply.send({ received: true });
    } catch (error) {
      fastify.log.error(`Webhook processing error: ${error.message}`);
      return reply.code(500).send({ error: 'Webhook processing failed' });
    }
  });
}

