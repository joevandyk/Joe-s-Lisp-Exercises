;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; indent-tabs-mode: nil -*-
;;;
;;; --- Package definition.
;;;

(in-package :common-lisp-user)

(defpackage :net.sockets
  (:nicknames #:sockets)
  (:use :iolib.base :cffi :io.streams)
  (:import-from #:iolib.syscalls #:defsyscall #:size-of-int
                #:size-t #:ssize-t #:pid-t #:uid-t #:gid-t
                #:timeval #:size-of-timeval #:sec #:usec)
  (:import-from #:io.multiplex #:decode-timeout)
  (:export
   ;; Conditions
   #:socket-error
   #:socket-address-in-use-error
   #:socket-address-not-available-error
   #:socket-already-connected-error
   #:socket-connection-aborted-error
   #:socket-connection-refused-error
   #:socket-connection-reset-error
   #:socket-connection-timeout-error
   #:socket-endpoint-shutdown-error
   #:socket-host-down-error
   #:socket-host-unreachable-error
   #:socket-network-down-error
   #:socket-network-reset-error
   #:socket-network-unreachable-error
   #:socket-no-buffer-space-error
   #:socket-no-network-error
   #:socket-not-connected-error
   #:socket-operation-not-supported-error
   #:socket-option-not-supported-error
   #:resolver-error
   #:resolver-again-error
   #:resolver-fail-error
   #:resolver-no-name-error
   #:resolver-unknown-error
   #:unknown-interface
   #:unknown-protocol
   #:unknown-service

   ;; Condition Accessors
   #:error-code
   #:error-identifier
   #:error-message
   #:resolver-error-datum
   #:unknown-protocol-datum
   #:unknown-service-datum
   #:unknown-interface-datum

   ;; Address Classes
   #:address
   #:inet-address
   #:ipv4-address
   #:ipv6-address
   #:local-address

   ;; Address Functions
   #:address-type
   #:address-to-string
   #:address-to-vector
   #:copy-address
   #:ensure-address
   #:make-address

   ;; Well-known Addresses
   #:+ipv4-loopback+
   #:+ipv4-unspecified+
   #:+ipv6-interface-local-all-nodes+
   #:+ipv6-interface-local-all-routers+
   #:+ipv6-link-local-all-nodes+
   #:+ipv6-link-local-all-routers+
   #:+ipv6-loopback+
   #:+ipv6-site-local-all-routers+
   #:+ipv6-unspecified+
   #:+max-ipv4-value+
   #:+any-host+
   #:+loopback+

   ;; Address Predicates
   #:abstract-address-p
   #:address=
   #:address-equal-p
   #:addressp
   #:inet-address-loopback-p
   #:inet-address-multicast-p
   #:inet-address-p
   #:inet-address-type
   #:inet-address-unicast-p
   #:inet-address-unspecified-p
   #:ipv4-address-p
   #:ipv6-address-p
   #:ipv6-admin-local-multicast-p
   #:ipv6-global-multicast-p
   #:ipv6-global-unicast-p
   #:ipv6-interface-local-multicast-p
   #:ipv6-ipv4-mapped-p
   #:ipv6-link-local-multicast-p
   #:ipv6-link-local-unicast-p
   #:ipv6-multicast-type
   #:ipv6-organization-local-multicast-p
   #:ipv6-reserved-multicast-p
   #:ipv6-site-local-multicast-p
   #:ipv6-site-local-unicast-p
   #:ipv6-solicited-node-multicast-p
   #:ipv6-transient-multicast-p
   #:ipv6-unassigned-multicast-p
   #:ipv6-unicast-type
   #:local-address-p

   ;; Network masks and subnets
   #:make-netmask
   #:ensure-netmask
   #:ipv4-network
   #:ipv4-network=
   #:inet-address-private-p
   #:inet-address-network-portion
   #:inet-address-host-portion
   #:inet-address-in-network-p
   #:inet-addresses-in-same-network-p
   #:inet-address-network-class

   ;; Low-level Address Conversion
   #:colon-separated-to-vector
   #:dotted-to-integer
   #:dotted-to-vector
   #:integer-to-dotted
   #:integer-to-vector
   #:string-address-to-vector
   #:vector-to-colon-separated
   #:vector-to-dotted
   #:vector-to-integer
   #:map-ipv4-address-to-ipv6
   #:map-ipv6-address-to-ipv4

   ;; Hostname, Service, and Protocol Lookups
   #:ensure-hostname
   #:lookup-host
   #:lookup-protocol
   #:lookup-service

   ;; Network Interface Lookup
   #:list-network-interfaces
   #:interface-index
   #:interface-name
   #:lookup-interface
   #:make-interface

   ;; Socket Classes
   #:active-socket
   #:datagram-socket
   #:internet-socket
   #:local-socket
   #:passive-socket
   #:socket
   #:socket-datagram-internet-active
   #:socket-datagram-local-active
   #:socket-stream-internet-active
   #:socket-stream-internet-passive
   #:socket-stream-local-active
   #:socket-stream-local-passive
   #:stream-socket

   ;; Socket Methods
   #:accept-connection
   #:bind-address
   #:connect
   #:disconnect
   #:ipv6-socket-p
   #:listen-on
   #:local-filename
   #:local-host
   #:local-name
   #:local-port
   #:make-socket
   #:make-socket-from-fd
   #:make-socket-pair
   #:receive-file-descriptor
   #:receive-from
   #:remote-filename
   #:remote-host
   #:remote-name
   #:remote-port
   #:send-file-descriptor
   #:send-to
   #:shutdown
   #:socket-connected-p
   #:socket-address-family
   #:socket-open-p
   #:socket-option
   #:socket-os-fd
   #:socket-protocol
   #:socket-type
   #:with-open-socket
   #:with-accept-connection

   ;; Specials
   #:*default-backlog-size*
   #:*default-linger-seconds*
   #:*ipv6*
   #:*dns-nameservers*
   #:*dns-domain*
   #:*dns-search-domain*

   ;; Miscellaneous
   #:ip-address
   ))
