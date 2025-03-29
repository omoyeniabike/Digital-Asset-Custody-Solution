;; Multi-Signature Authorization Contract
;; Requires multiple approvals for transactions

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-map signers { address: principal } { active: bool })
(define-data-var required-signatures uint u2)
(define-data-var transaction-id-counter uint u0)

;; Define transaction map
(define-map transactions
  { tx-id: uint }
  {
    asset-id: uint,
    action: (string-ascii 32),
    initiator: principal,
    target: principal,
    status: (string-ascii 16),
    signature-count: uint,
    created-at: uint,
    executed-at: uint
  }
)

;; Define signatures map
(define-map transaction-signatures
  { tx-id: uint, signer: principal }
  { signed: bool }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_NOT_SIGNER u2)
(define-constant ERR_TX_NOT_FOUND u3)
(define-constant ERR_ALREADY_SIGNED u4)
(define-constant ERR_INSUFFICIENT_SIGNATURES u5)
(define-constant ERR_ALREADY_EXECUTED u6)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Check if caller is an active signer
(define-private (is-active-signer (address principal))
  (default-to false (get active (map-get? signers { address: address })))
)

;; Add a signer
(define-public (add-signer (signer principal))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (map-set signers { address: signer } { active: true })
    (ok true)
  )
)

;; Remove a signer
(define-public (remove-signer (signer principal))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (map-set signers { address: signer } { active: false })
    (ok true)
  )
)

;; Update required signatures
(define-public (set-required-signatures (count uint))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (var-set required-signatures count)
    (ok true)
  )
)

;; Create a new transaction that requires signatures
(define-public (create-transaction
    (asset-id uint)
    (action (string-ascii 32))
    (target principal)
  )
  (let
    (
      (tx-id (var-get transaction-id-counter))
      (current-time block-height)
    )
    ;; Check if caller is an active signer
    (asserts! (is-active-signer tx-sender) (err ERR_NOT_SIGNER))

    ;; Increment transaction ID counter
    (var-set transaction-id-counter (+ (var-get transaction-id-counter) u1))

    ;; Create transaction
    (map-insert transactions
      { tx-id: tx-id }
      {
        asset-id: asset-id,
        action: action,
        initiator: tx-sender,
        target: target,
        status: "pending",
        signature-count: u1,
        created-at: current-time,
        executed-at: u0
      }
    )

    ;; Record first signature (from creator)
    (map-insert transaction-signatures
      { tx-id: tx-id, signer: tx-sender }
      { signed: true }
    )

    (ok tx-id)
  )
)

;; Sign a transaction
(define-public (sign-transaction (tx-id uint))
  (let
    (
      (tx (unwrap! (map-get? transactions { tx-id: tx-id }) (err ERR_TX_NOT_FOUND)))
    )
    ;; Check if caller is an active signer
    (asserts! (is-active-signer tx-sender) (err ERR_NOT_SIGNER))

    ;; Check if transaction is still pending
    (asserts! (is-eq (get status tx) "pending") (err ERR_ALREADY_EXECUTED))

    ;; Check if caller has already signed
    (asserts! (is-none (map-get? transaction-signatures { tx-id: tx-id, signer: tx-sender }))
              (err ERR_ALREADY_SIGNED))

    ;; Record signature
    (map-insert transaction-signatures
      { tx-id: tx-id, signer: tx-sender }
      { signed: true }
    )

    ;; Update signature count
    (map-set transactions
      { tx-id: tx-id }
      (merge tx { signature-count: (+ (get signature-count tx) u1) })
    )

    (ok true)
  )
)

;; Execute a transaction if it has enough signatures
(define-public (execute-transaction (tx-id uint))
  (let
    (
      (tx (unwrap! (map-get? transactions { tx-id: tx-id }) (err ERR_TX_NOT_FOUND)))
      (current-time block-height)
    )
    ;; Check if transaction is still pending
    (asserts! (is-eq (get status tx) "pending") (err ERR_ALREADY_EXECUTED))

    ;; Check if there are enough signatures
    (asserts! (>= (get signature-count tx) (var-get required-signatures))
              (err ERR_INSUFFICIENT_SIGNATURES))

    ;; Update transaction status to executed
    (map-set transactions
      { tx-id: tx-id }
      (merge tx {
        status: "executed",
        executed-at: current-time
      })
    )

    (ok true)
  )
)

;; Get transaction details
(define-read-only (get-transaction (tx-id uint))
  (match (map-get? transactions { tx-id: tx-id })
    tx (ok tx)
    (err ERR_TX_NOT_FOUND)
  )
)

;; Check if a user has signed a transaction
(define-read-only (has-signed (tx-id uint) (signer principal))
  (is-some (map-get? transaction-signatures { tx-id: tx-id, signer: signer }))
)

