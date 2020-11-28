//
//  Mutex.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import Foundation

class Mutex {
    private var pthread_mutex = pthread_mutex_t()

    init() {
        var pthread_mutexattr = pthread_mutexattr_t()
        if pthread_mutexattr_init(&pthread_mutexattr) != 0 {
            Logger.traceError(message: "Failed to initialize mutex attr")
            return
        }
        pthread_mutexattr_settype(&pthread_mutexattr, PTHREAD_MUTEX_NORMAL)

        if pthread_mutex_init(&pthread_mutex, &pthread_mutexattr) != 0 {
            Logger.traceError(message: "Failed to initialize the mutex")
        }

        if pthread_mutexattr_destroy(&pthread_mutexattr) != 0 {
            Logger.traceError(message: "Failed to destroy mutext attr")
        }
    }

    deinit {
        if pthread_mutex_destroy(&pthread_mutex) != 0 {
            Logger.traceError(message: "Failed to destroy mutex")
        }
    }

    func sync<T>(closure: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }

        return try closure()
    }

    func lock() {
        pthread_mutex_lock(&pthread_mutex)
    }

    func unlock() {
        pthread_mutex_unlock(&pthread_mutex)
    }
}
