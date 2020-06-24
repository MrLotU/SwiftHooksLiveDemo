import SwiftHooks
import Discord
import Foundation

print("Hello, raywenderlich.com community care!")

let myHooks = SwiftHooks()

guard let token = ProcessInfo.processInfo.environment["BOT_TOKEN"] else {
    fatalError("We don't have a valid bot token!")
}

try myHooks.hook(DiscordHook.self, .init(token: token))

try myHooks.register(CookiePlugin())
try myHooks.register(RolePlugin())
try myHooks.register(TagsPlugin())

try myHooks.run()
