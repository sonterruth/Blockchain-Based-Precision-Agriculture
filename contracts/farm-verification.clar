;; Farm Verification Contract
;; Validates legitimate agricultural producers

(define-data-var admin principal tx-sender)

;; Farm status: 0 = unverified, 1 = verified, 2 = suspended
(define-map farms
  { owner: principal }
  {
    name: (string-utf8 100),
    location: (string-utf8 100),
    status: uint,
    verification-date: uint
  }
)

;; Register a new farm (unverified by default)
(define-public (register-farm (name (string-utf8 100)) (location (string-utf8 100)))
  (let ((caller tx-sender))
    (if (is-some (map-get? farms { owner: caller }))
      (err u1) ;; Farm already registered
      (ok (map-set farms
            { owner: caller }
            {
              name: name,
              location: location,
              status: u0,
              verification-date: u0
            }
          )
      )
    )
  )
)

;; Verify a farm (admin only)
(define-public (verify-farm (farm-owner principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
      (match (map-get? farms { owner: farm-owner })
        farm-data (ok (map-set farms
                      { owner: farm-owner }
                      (merge farm-data {
                        status: u1,
                        verification-date: block-height
                      })
                    ))
        (err u3) ;; Farm not found
      )
      (err u2) ;; Not authorized
    )
  )
)

;; Suspend a farm (admin only)
(define-public (suspend-farm (farm-owner principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
      (match (map-get? farms { owner: farm-owner })
        farm-data (ok (map-set farms
                      { owner: farm-owner }
                      (merge farm-data { status: u2 })
                    ))
        (err u3) ;; Farm not found
      )
      (err u2) ;; Not authorized
    )
  )
)

;; Check if a farm is verified
(define-read-only (is-farm-verified (farm-owner principal))
  (match (map-get? farms { owner: farm-owner })
    farm-data (is-eq (get status farm-data) u1)
    false
  )
)

;; Get farm details
(define-read-only (get-farm-details (farm-owner principal))
  (map-get? farms { owner: farm-owner })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
      (ok (var-set admin new-admin))
      (err u2) ;; Not authorized
    )
  )
)
