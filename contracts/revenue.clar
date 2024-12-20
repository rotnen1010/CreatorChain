;; Revenue Tracking Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))

(define-map content-revenue
  { content-id: uint }
  { total-revenue: uint }
)

(define-public (record-revenue (content-id uint) (amount uint))
  (let
    (
      (current-revenue (default-to { total-revenue: u0 } (map-get? content-revenue { content-id: content-id })))
    )
    (ok (map-set content-revenue
      { content-id: content-id }
      { total-revenue: (+ (get total-revenue current-revenue) amount) }
    ))
  )
)

(define-read-only (get-content-revenue (content-id uint))
  (default-to { total-revenue: u0 } (map-get? content-revenue { content-id: content-id }))
)

