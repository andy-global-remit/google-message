## ADDED Requirements

### Requirement: Provision baseline GCP platform with Terraform modules
The infrastructure MUST be provisioned from Terraform module composition and include Cloud Identity Platform, Cloud Functions (2nd gen), Firestore, Secret Manager, and IAM role bindings required for runtime execution.

#### Scenario: Root module wires all platform modules
- **WHEN** Terraform root module is initialized
- **THEN** it references modules for `project-services`, `identity-platform`, `firestore`, `secret-manager`, `cloud-functions`, and `iam`
- **AND** module inputs include `project_id`, `region`, and environment-specific values.

#### Scenario: Required APIs are enabled
- **WHEN** Terraform plan is generated
- **THEN** the configuration enables `cloudfunctions.googleapis.com`
- **AND** `run.googleapis.com`
- **AND** `firestore.googleapis.com`
- **AND** `secretmanager.googleapis.com`
- **AND** `identitytoolkit.googleapis.com`
- **AND** `cloudbuild.googleapis.com`
- **AND** `artifactregistry.googleapis.com`
- **AND** `logging.googleapis.com`
- **AND** `iam.googleapis.com`.

### Requirement: Cloud Functions expose encrypted messenger API surface
The backend MUST expose HTTP endpoints for auth, key management, encrypted message exchange, and push subscription management.

#### Scenario: Public auth endpoint
- **WHEN** a client calls `POST /auth/google` with a Google ID token
- **THEN** the function verifies the token and upserts `users/{uid}`
- **AND** returns app JWT with `uid` and `isNewUser`.

#### Scenario: Authenticated key and chat endpoints
- **WHEN** a client calls `/keys/*`, `/chat/*`, or `/push/*`
- **THEN** the backend validates app JWT
- **AND** rejects unauthenticated or expired tokens.

### Requirement: Firestore stores only encrypted artifacts and metadata
Firestore data model MUST store ciphertext, ratchet metadata, and public key bundles without storing plaintext message content or private keys.

#### Scenario: Sending encrypted message
- **WHEN** `POST /chat/send` is called
- **THEN** server stores `header`, `ciphertext`, and envelope metadata in `rooms/{roomId}/messages/{messageId}`
- **AND** no plaintext payload field is persisted.

#### Scenario: Identity and prekey bundle persistence
- **WHEN** `/keys/identity` and `/keys/prekeys` succeed
- **THEN** Firestore stores identity public key, signing public key, signed prekey, and one-time prekeys
- **AND** server tracks `oneTimePreKeyCount`.

### Requirement: Prekey lifecycle supports X3DH session setup
The system MUST support uploading, serving, and consuming one-time prekeys to establish first-message sessions.

#### Scenario: Bundle fetch for session initiation
- **WHEN** sender calls `GET /keys/bundle?uid={uid}`
- **THEN** response includes target identity public key, signing public key, signed prekey, and one one-time prekey if available.

#### Scenario: One-time prekey consumption on initial message
- **WHEN** `POST /chat/send` includes `type=x3dh_initial` and `usedOneTimePreKeyId`
- **THEN** server atomically removes consumed one-time prekey for the recipient
- **AND** decrements or recomputes available one-time prekey count.

### Requirement: Web Push uses VAPID and privacy-preserving payloads
The platform MUST store web push subscriptions and send notification hints without plaintext message content.

#### Scenario: Register push subscription
- **WHEN** authenticated client calls `POST /push/subscribe`
- **THEN** subscription is stored at `pushSubscriptions/{uid}/devices/{deviceId}`.

#### Scenario: Trigger push on new message
- **WHEN** encrypted message is accepted by `/chat/send`
- **THEN** backend sends push notifications using VAPID keys from Secret Manager
- **AND** payload includes only notification hint fields such as `title`, `body`, and `roomId`
- **AND** does not include decrypted message body.
