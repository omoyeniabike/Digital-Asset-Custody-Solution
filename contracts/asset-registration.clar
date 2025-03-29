;; Asset Registration Contract
;; Records details of managed digital assets

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var asset-id-counter uint u0)

;; Define assets map
(define-map assets
  { asset-id: uint }
  {
    name: (string-ascii 64),
    asset-type: (string-ascii 32),
    registration-date: uint,
    owner: principal,
    metadata: (string-ascii 128),
    status: (string-ascii 16)
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ASSET_NOT_FOUND u3)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Register a new asset
(define-public (register-asset
    (name (string-ascii 64))
    (asset-type (string-ascii 32))
    (metadata (string-ascii 128))
  )
  (let
    (
      (asset-id (var-get asset-id-counter))
      (current-time block-height)
    )
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))

    ;; Increment asset ID counter
    (var-set asset-id-counter (+ (var-get asset-id-counter) u1))

    ;; Insert new asset into map
    (map-insert assets
      { asset-id: asset-id }
      {
        name: name,
        asset-type: asset-type,
        registration-date: current-time,
        owner: tx-sender,
        metadata: metadata,
        status: "active"
      }
    )

    ;; Return the new asset ID
    (ok asset-id)
  )
)

;; Get asset details
(define-read-only (get-asset (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset (ok asset)
    (err ERR_ASSET_NOT_FOUND)
  )
)

;; Update asset status
(define-public (update-asset-status (asset-id uint) (new-status (string-ascii 16)))
  (let
    ((asset (unwrap! (map-get? assets { asset-id: asset-id }) (err ERR_ASSET_NOT_FOUND))))

    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))

    (map-set assets
      { asset-id: asset-id }
      (merge asset { status: new-status })
    )

    (ok true)
  )
)

;; Update asset metadata
(define-public (update-asset-metadata (asset-id uint) (new-metadata (string-ascii 128)))
  (let
    ((asset (unwrap! (map-get? assets { asset-id: asset-id }) (err ERR_ASSET_NOT_FOUND))))

    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))

    (map-set assets
      { asset-id: asset-id }
      (merge asset { metadata: new-metadata })
    )

    (ok true)
  )
)

;; Transfer asset ownership
(define-public (transfer-asset-ownership (asset-id uint) (new-owner principal))
  (let
    ((asset (unwrap! (map-get? assets { asset-id: asset-id }) (err ERR_ASSET_NOT_FOUND))))

    (asserts! (is-eq tx-sender (get owner asset)) (err ERR_UNAUTHORIZED))

    (map-set assets
      { asset-id: asset-id }
      (merge asset { owner: new-owner })
    )

    (ok true)
  )
)
