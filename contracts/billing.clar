;; Billing Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))

;; Data Maps
(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-map payment-history
  { user: principal, payment-id: uint }
  {
    amount: uint,
    timestamp: uint,
    plan-id: uint
  }
)

;; Data Variables
(define-data-var last-payment-id uint u0)

;; Public Functions

;; Add funds to user balance
(define-public (add-funds (amount uint))
  (let
    (
      (user-balance (default-to { balance: u0 } (map-get? user-balances { user: tx-sender })))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set user-balances
      { user: tx-sender }
      { balance: (+ (get balance user-balance) amount) }
    )
    (ok true)
  )
)

;; Process payment for subscription
(define-public (process-payment (plan-id uint))
  (let
    (
      (plan (unwrap! (contract-call? .subscription get-plan plan-id) err-not-found))
      (user-balance (default-to { balance: u0 } (map-get? user-balances { user: tx-sender })))
      (payment-id (+ (var-get last-payment-id) u1))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (>= (get balance user-balance) (get price plan)) err-insufficient-balance)
    (map-set user-balances
      { user: tx-sender }
      { balance: (- (get balance user-balance) (get price plan)) }
    )
    (map-set payment-history
      { user: tx-sender, payment-id: payment-id }
      {
        amount: (get price plan),
        timestamp: current-time,
        plan-id: plan-id
      }
    )
    (var-set last-payment-id payment-id)
    (try! (contract-call? .subscription subscribe plan-id))
    (ok payment-id)
  )
)

;; Read-only Functions

;; Get user balance
(define-read-only (get-balance (user principal))
  (ok (get balance (default-to { balance: u0 } (map-get? user-balances { user: user }))))
)

;; Get payment details
(define-read-only (get-payment (user principal) (payment-id uint))
  (ok (unwrap! (map-get? payment-history { user: user, payment-id: payment-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set last-payment-id u0)
)
