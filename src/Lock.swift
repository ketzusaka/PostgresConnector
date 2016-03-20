//
//  Lock.swift
//  PostgresConnector
//
//  Created by James Richard on 3/15/16.
//
//

// Code from Swift Foundation project

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

class Lock {

    let mutex = UnsafeMutablePointer<pthread_mutex_t>(allocatingCapacity: 1)

    init() {
        pthread_mutex_init(mutex, nil)
    }

    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deinitialize(count: 1)
        mutex.deallocateCapacity(1)
    }

    func lock() {
        pthread_mutex_lock(mutex)
    }

    func unlock() {
        pthread_mutex_unlock(mutex)
    }

    func tryLock() -> Bool {
        return pthread_mutex_trylock(mutex) == 0
    }
    
}
