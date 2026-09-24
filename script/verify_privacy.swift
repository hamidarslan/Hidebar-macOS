import Foundation

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fputs("Privacy check failed: \(message)\n", stderr); exit(1) }
}
func plist(_ url: URL) throws -> NSDictionary {
    let value = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
    guard let dict = value as? NSDictionary else { throw NSError(domain: "Invalid plist", code: 1) }
    return dict
}
let app = URL(fileURLWithPath: CommandLine.arguments[1])
let resources = app.appendingPathComponent("Contents/Resources")
let manifest = try plist(resources.appendingPathComponent("PrivacyInfo.xcprivacy"))
require(manifest["NSPrivacyTracking"] as? Bool == false, "tracking must be disabled")
require((manifest["NSPrivacyTrackingDomains"] as? [String]) == [], "tracking domains must be empty")
require((manifest["NSPrivacyCollectedDataTypes"] as? [NSDictionary]) == [], "collected data must be empty")
let reasons = manifest["NSPrivacyAccessedAPITypes"] as? [NSDictionary]
require(reasons?.count == 1, "review any newly used API categories")
require(reasons?.first?["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults", "declare preferences access")
require(reasons?.first?["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["CA92.1"], "preferences must be app-only")
require(FileManager.default.fileExists(atPath: resources.appendingPathComponent("PRIVACY.md").path), "bundle offline policy")
let architectures = CommandLine.arguments.dropFirst(2)
for arch in architectures {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
    process.arguments = ["-d", "--arch", arch, "--entitlements", "-", "--xml", app.path]
    process.standardOutput = output
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    require(process.terminationStatus == 0, "read signed entitlements for \(arch)")
    let signed = try PropertyListSerialization.propertyList(from: data, format: nil) as? NSDictionary
    require(signed == ["com.apple.security.app-sandbox": true] as NSDictionary,
            "\(arch) must have only the sandbox entitlement; network, file, debug, and exception grants are forbidden")
}
print("Privacy manifest, offline policy, and exact signed entitlement allowlist passed.")
