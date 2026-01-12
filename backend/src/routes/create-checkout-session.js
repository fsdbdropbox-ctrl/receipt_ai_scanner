import Stripe from 'stripe';

// STRIPE_SECRET_KEY is validated in app.js before this module is used
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
// Default Stripe price ID (can be overridden via env if needed, but not required)
const STRIPE_PRICE_ID = process.env.STRIPE_PRICE_ID || 'price_1SdvstQk2i4Ptr2gYzneU6kS';
// Default frontend URL (legacy route - AuditReady uses OAuth redirects)
const FRONTEND_URL = process.env.FRONTEND_URL || 'https://receiptscanner.app';

export async function createCheckoutSessionRoute(fastify) {
  fastify.post('/api/create-checkout-session', async (request, reply) => {
    const installId = request.installId;
    const { installId: bodyInstallId } = request.body;

    if (installId !== bodyInstallId) {
      return reply.code(400).send({ error: 'Install ID mismatch' });
    }

    try {
      const session = await stripe.checkout.sessions.create({
        mode: 'subscription',
        payment_method_types: ['card'],
        line_items: [
          {
            price: STRIPE_PRICE_ID,
            quantity: 1,
          },
        ],
        subscription_data: {
          trial_period_days: 7,
          metadata: {
            installId: installId,
          },
        },
        success_url: `${FRONTEND_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${FRONTEND_URL}/cancel`,
        client_reference_id: installId,
      });

      return reply.send({ url: session.url });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({ error: 'Failed to create checkout session' });
    }
  });
}

