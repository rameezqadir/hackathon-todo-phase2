**Content:**
```typescript
/**
 * Better Auth configuration
 * [Task]: T-009
 * [From]: speckit.specify FR-3
 */

import { betterAuth } from "better-auth"

export const auth = betterAuth({
  database: {
    provider: "postgres",
    url: process.env.DATABASE_URL!,
  },
  emailAndPassword: {
    enabled: true,
  },
  jwt: {
    enabled: true,
  },
})

export type Session = typeof auth.$Infer.Session
