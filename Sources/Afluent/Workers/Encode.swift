//
//  Encode.swift
//
//
//  Created by Tyler Thompson on 10/28/23.
//

import Foundation

public protocol TopLevelEncoder<Output> {
    associatedtype Output
    func encode<T: Encodable>(_ value: T) throws -> Output
}

extension JSONEncoder: TopLevelEncoder { }

extension Workers {
    struct Encode<Upstream: AsynchronousUnitOfWork, Encoder: TopLevelEncoder & Sendable, Success: Sendable>: AsynchronousUnitOfWork where Success == Encoder.Output, Upstream.Success: Encodable {
        let state = TaskState<Success>()
        let upstream: Upstream
        let encoder: Encoder

        func _operation() async throws -> AsynchronousOperation<Success> {
            AsynchronousOperation {
                try encoder.encode(await upstream.operation())
            }
        }
    }
}

extension AsynchronousUnitOfWork {
    /// Encodes the successful output values from the upstream `AsynchronousUnitOfWork` using the provided encoder.
    ///
    /// - Parameter encoder: The encoder to use for encoding the successful output values.
    ///
    /// - Returns: An `AsynchronousUnitOfWork` emitting the encoded values as output of type `E.Output`.
    ///
    /// - Note: The returned `AsynchronousUnitOfWork` will fail if the encoding process fails.
    public func encode<E: TopLevelEncoder & Sendable>(encoder: E) -> some AsynchronousUnitOfWork<E.Output> where Success: Encodable, E.Output: Sendable {
        Workers.Encode(upstream: self, encoder: encoder)
    }
}
