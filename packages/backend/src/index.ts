/*
 * Hi!
 *
 * Note that this is an EXAMPLE Backstage backend. Please check the README.
 *
 * Happy hacking!
 */

import { createBackend } from '@backstage/backend-defaults';

const backend = createBackend();

backend.add(import('@backstage/plugin-app-backend/alpha'));
backend.add(import('@backstage/plugin-proxy-backend/alpha'));
backend.add(import('@backstage/plugin-scaffolder-backend/alpha'));
backend.add(import('@backstage/plugin-techdocs-backend/alpha'));

// auth plugin
backend.add(import('@backstage/plugin-auth-backend'));
// See https://backstage.io/docs/backend-system/building-backends/migrating#the-auth-plugin
// backend.add(import('@backstage/plugin-auth-backend-module-guest-provider'));
// backend.add(import('@backstage/plugin-auth-backend-module-gcp-iap-provider'));
// See https://backstage.io/docs/auth/guest/provider

import { createBackendModule } from '@backstage/backend-plugin-api';
import { gcpIapAuthenticator } from '@backstage/plugin-auth-backend-module-gcp-iap-provider';
import {
  authProvidersExtensionPoint,
  createProxyAuthProviderFactory,
} from '@backstage/plugin-auth-node';

import { stringifyEntityRef, DEFAULT_NAMESPACE } from '@backstage/catalog-model';

const customAuth = createBackendModule({
  pluginId: 'auth',
  moduleId: 'all-allow-auth-provider',
  register(reg) {
    reg.registerInit({
      deps: { providers: authProvidersExtensionPoint },
      async init({ providers }) {
        providers.registerProvider({
          providerId: 'gcp-iap',
          factory: createProxyAuthProviderFactory({
            authenticator: gcpIapAuthenticator,
            async signInResolver({ profile }, ctx) {
              if (!profile.email) {
                throw new Error(
                  'Login failed, user profile does not contain an email. Please contact your administrator.',
                );
              }
              const [localPart, _] = profile.email.split('@');
              const userEntity = stringifyEntityRef({
                kind: 'User',
                name: localPart,
                namespace: DEFAULT_NAMESPACE,
              });
              return ctx.issueToken({
                claims: {
                  sub: userEntity,
                  ent: [userEntity],
                },
              });
            }
          }),
        });
      },
    });
  },
});
backend.add(customAuth);


// catalog plugin
backend.add(import('@backstage/plugin-catalog-backend/alpha'));
backend.add(
  import('@backstage/plugin-catalog-backend-module-scaffolder-entity-model'),
);

// permission plugin
backend.add(import('@backstage/plugin-permission-backend/alpha'));
backend.add(
  import('@backstage/plugin-permission-backend-module-allow-all-policy'),
);

// search plugin
backend.add(import('@backstage/plugin-search-backend/alpha'));
backend.add(import('@backstage/plugin-search-backend-module-catalog/alpha'));
backend.add(import('@backstage/plugin-search-backend-module-techdocs/alpha'));
backend.add(import('@backstage/plugin-search-backend-module-pg/alpha'));

// Kubernetes plugin
backend.add(import('@backstage/plugin-kubernetes-backend/alpha'));

backend.start();
