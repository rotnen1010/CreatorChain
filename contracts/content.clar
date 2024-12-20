;; Content Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))

(define-data-var content-nonce uint u0)

(define-map contents
  { content-id: uint }
  {
    creator: principal,
    title: (string-utf8 256),
    description: (string-utf8 1024),
    ipfs-hash: (string-ascii 64),
    price: uint,
    royalty-percentage: uint
  }
)

(define-non-fungible-token content-token uint)

(define-public (create-content (title (string-utf8 256)) (description (string-utf8 1024)) (ipfs-hash (string-ascii 64)) (price uint) (royalty-percentage uint))
  (let
    (
      (content-id (var-get content-nonce))
    )
    (asserts! (< royalty-percentage u100) (err u400))
    (try! (nft-mint? content-token content-id tx-sender))
    (map-set contents
      { content-id: content-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        ipfs-hash: ipfs-hash,
        price: price,
        royalty-percentage: royalty-percentage
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

(define-public (transfer-content (content-id uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? content-token content-id) (err u404))) (err u401))
    (try! (nft-transfer? content-token content-id tx-sender recipient))
    (ok true)
  )
)

(define-read-only (get-content (content-id uint))
  (map-get? contents { content-id: content-id })
)

