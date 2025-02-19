;; Subscription Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))

;; Data Variables
(define-data-var last-plan-id uint u0)

;; Data Maps
(define-map subscription-plans
  { plan-id: uint }
  {
    name: (string-ascii 50),
    price: uint,
    duration: uint,
    features: (list 10 (string-ascii 50))
  }
)

(define-map user-subscriptions
  { user: principal }
  {
    plan-id: uint,
    start-date: uint,
    end-date: uint
  }
)

;; Public Functions

;; Create a new subscription plan
(define-public (create-plan (name (string-ascii 50)) (price uint) (duration uint) (features (list 10 (string-ascii 50))))
  (let
    (
      (new-plan-id (+ (var-get last-plan-id) u1))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set subscription-plans
      { plan-id: new-plan-id }
      {
        name: name,
        price: price,
        duration: duration,
        features: features
      }
    )
    (var-set last-plan-id new-plan-id)
    (ok new-plan-id)
  )
)

;; Subscribe to a plan
(define-public (subscribe (plan-id uint))
  (let
    (
      (plan (unwrap! (map-get? subscription-plans { plan-id: plan-id }) err-not-found))
      (current-time block-height)
    )
    (map-set user-subscriptions
      { user: tx-sender }
      {
        plan-id: plan-id,
        start-date: current-time,
        end-date: (+ current-time (get duration plan))
      }
    )
    (ok true)
  )
)

;; Cancel subscription
(define-public (cancel-subscription)
  (let
    (
      (subscription (unwrap! (map-get? user-subscriptions { user: tx-sender }) err-not-found))
    )
    (map-delete user-subscriptions { user: tx-sender })
    (ok true)
  )
)

;; Read-only functions

;; Get plan details
(define-read-only (get-plan (plan-id uint))
  (ok (unwrap! (map-get? subscription-plans { plan-id: plan-id }) err-not-found))
)

;; Get user subscription
(define-read-only (get-user-subscription (user principal))
  (ok (unwrap! (map-get? user-subscriptions { user: user }) err-not-found))
)

;; Initialize contract
(begin
  (var-set last-plan-id u0)
)

