import Foundation
import Darwin

// Separate test bundle; never runs inside the distributed Hidebar executable.
func check(_ value: Bool, _ message: String) {
    guard value else { fputs("FAIL: \(message)\n", stderr); exit(1) }
    print("PASS: \(message)")
}
let marker = CommandLine.arguments[1]
let file = open(marker, O_RDONLY)
if file >= 0 { close(file) }
check(file == -1 && (errno == EPERM || errno == EACCES), "sandbox denies reading outside-container marker")
let writeFile = open(marker + ".write-test", O_WRONLY | O_CREAT | O_EXCL, S_IRUSR | S_IWUSR)
if writeFile >= 0 { close(writeFile); unlink(marker + ".write-test") }
check(writeFile == -1 && (errno == EPERM || errno == EACCES), "sandbox denies writing outside container")
let socketFD = socket(AF_INET, SOCK_STREAM, 0)
check(socketFD >= 0, "create local test socket")
var address = sockaddr_in()
address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
address.sin_family = sa_family_t(AF_INET)
address.sin_port = UInt16(9).bigEndian
address.sin_addr.s_addr = inet_addr("127.0.0.1")
let connected = withUnsafePointer(to: &address) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        connect(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
    }
}
let connectError = errno
close(socketFD)
check(connected == -1 && (connectError == EPERM || connectError == EACCES), "sandbox denies outbound network even to loopback")
let listener = socket(AF_INET, SOCK_STREAM, 0)
address.sin_port = 0
let bound = withUnsafePointer(to: &address) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        bind(listener, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
    }
}
let bindError = errno
close(listener)
check(bound == -1 && (bindError == EPERM || bindError == EACCES), "sandbox denies inbound network binding")
let defaults = UserDefaults.standard
defaults.set("local-roundtrip", forKey: "privacyProbe")
check(defaults.string(forKey: "privacyProbe") == "local-roundtrip", "sandbox permits app-local preferences")
defaults.removeObject(forKey: "privacyProbe")
print("All runtime sandbox probes passed.")
