;; Content Monetization Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-already-exists (err u409))

;; Data vars
(define-data-var content-nonce uint u0)

;; Data maps
(define-map contents
  { content-id: uint }
  {
    creator: principal,
    title: (string-utf8 256),
    description: (string-utf8 1024),
    ipfs-hash: (string-ascii 64),
    price: uint,
    royalty-percentage: uint,
    total-revenue: uint
  }
)

(define-map subscriptions
  { user: principal, content-id: uint }
  { expiration: uint }
)

;; NFT definitions
(define-non-fungible-token content-nft uint)

;; Public functions
(define-public (create-content (title (string-utf8 256)) (description (string-utf8 1024)) (ipfs-hash (string-ascii 64)) (price uint) (royalty-percentage uint))
  (let
    (
      (content-id (var-get content-nonce))
    )
    (asserts! (< royalty-percentage u100) (err u400))
    (try! (nft-mint? content-nft content-id tx-sender))
    (map-set contents
      { content-id: content-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        ipfs-hash: ipfs-hash,
        price: price,
        royalty-percentage: royalty-percentage,
        total-revenue: u0
      }
    )
    (var-set content-nonce (+ content-id u1))
    (ok content-id)
  )
)

(define-public (update-content (content-id uint) (title (string-utf8 256)) (description (string-utf8 1024)) (ipfs-hash (string-ascii 64)) (price uint) (royalty-percentage uint))
  (let
    (
      (content (unwrap! (map-get? contents { content-id: content-id }) (err u404)))
    )
    (asserts! (is-eq (get creator content) tx-sender) (err u401))
    (asserts! (< royalty-percentage u100) (err u400))
    (ok (map-set contents
      { content-id: content-id }
      (merge content
        {
          title: title,
          description: description,
          ipfs-hash: ipfs-hash,
          price: price,
          royalty-percentage: royalty-percentage
        }
      )
    ))
  )
)

(define-public (purchase-content (content-id uint))
  (let
    (
      (content (unwrap! (map-get? contents { content-id: content-id }) (err u404)))
      (price (get price content))
    )
    (try! (stx-transfer? price tx-sender (get creator content)))
    (map-set subscriptions
      { user: tx-sender, content-id: content-id }
      { expiration: (+ block-height u1440) }  ;; Set expiration to 1 day (assuming 1 block per minute)
    )
    (map-set contents
      { content-id: content-id }
      (merge content { total-revenue: (+ (get total-revenue content) price) })
    )
    (ok true)
  )
)

(define-public (transfer-content (content-id uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? content-nft content-id) (err u404))) (err u401))
    (try! (nft-transfer? content-nft content-id tx-sender recipient))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-content (content-id uint))
  (map-get? contents { content-id: content-id })
)

(define-read-only (get-subscription (user principal) (content-id uint))
  (map-get? subscriptions { user: user, content-id: content-id })
)

(define-read-only (is-subscribed (user principal) (content-id uint))
  (match (map-get? subscriptions { user: user, content-id: content-id })
    subscription (> (get expiration subscription) block-height)
    false
  )
)

