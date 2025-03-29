;; Access Control Contract
;; Manages permissions for different user roles

;; Define data variables
(define-data-var contract-owner principal tx-sender)

;; Define roles
(define-map roles
  { role-id: (string-ascii 32) }
  {
    name: (string-ascii 64),
    description: (string-ascii 128),
    active: bool
  }
)

;; Define user roles
(define-map user-roles
  { user: principal, role-id: (string-ascii 32) }
  { assigned: bool }
)

;; Define permissions
(define-map permissions
  { permission-id: (string-ascii 32) }
  {
    name: (string-ascii 64),
    description: (string-ascii 128),
    active: bool
  }
)

;; Define role permissions
(define-map role-permissions
  { role-id: (string-ascii 32), permission-id: (string-ascii 32) }
  { assigned: bool }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ROLE_EXISTS u2)
(define-constant ERR_ROLE_NOT_FOUND u3)
(define-constant ERR_PERMISSION_EXISTS u4)
(define-constant ERR_PERMISSION_NOT_FOUND u5)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Create a new role
(define-public (create-role
    (role-id (string-ascii 32))
    (name (string-ascii 64))
    (description (string-ascii 128))
  )
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? roles { role-id: role-id })) (err ERR_ROLE_EXISTS))

    (map-insert roles
      { role-id: role-id }
      {
        name: name,
        description: description,
        active: true
      }
    )

    (ok true)
  )
)

;; Create a new permission
(define-public (create-permission
    (permission-id (string-ascii 32))
    (name (string-ascii 64))
    (description (string-ascii 128))
  )
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? permissions { permission-id: permission-id })) (err ERR_PERMISSION_EXISTS))

    (map-insert permissions
      { permission-id: permission-id }
      {
        name: name,
        description: description,
        active: true
      }
    )

    (ok true)
  )
)

;; Assign a role to a user
(define-public (assign-role-to-user (user principal) (role-id (string-ascii 32)))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? roles { role-id: role-id })) (err ERR_ROLE_NOT_FOUND))

    (map-insert user-roles
      { user: user, role-id: role-id }
      { assigned: true }
    )

    (ok true)
  )
)

;; Revoke a role from a user
(define-public (revoke-role-from-user (user principal) (role-id (string-ascii 32)))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))

    (map-delete user-roles { user: user, role-id: role-id })

    (ok true)
  )
)

;; Assign a permission to a role
(define-public (assign-permission-to-role (role-id (string-ascii 32)) (permission-id (string-ascii 32)))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? roles { role-id: role-id })) (err ERR_ROLE_NOT_FOUND))
    (asserts! (is-some (map-get? permissions { permission-id: permission-id })) (err ERR_PERMISSION_NOT_FOUND))

    (map-insert role-permissions
      { role-id: role-id, permission-id: permission-id }
      { assigned: true }
    )

    (ok true)
  )
)

;; Revoke a permission from a role
(define-public (revoke-permission-from-role (role-id (string-ascii 32)) (permission-id (string-ascii 32)))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))

    (map-delete role-permissions { role-id: role-id, permission-id: permission-id })

    (ok true)
  )
)

;; Check if a user has a specific role
(define-read-only (has-role (user principal) (role-id (string-ascii 32)))
  (is-some (map-get? user-roles { user: user, role-id: role-id }))
)

;; Check if a role has a specific permission
(define-read-only (has-permission (role-id (string-ascii 32)) (permission-id (string-ascii 32)))
  (is-some (map-get? role-permissions { role-id: role-id, permission-id: permission-id }))
)

