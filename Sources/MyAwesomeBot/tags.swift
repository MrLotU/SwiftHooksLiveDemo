import SwiftHooks
import Foundation

final class TagsPlugin: Plugin {
    
    var tags: [String: Tag] = [:]
    var analytics: [String: TagAnalytics] = [:]
    
    var commands: some Commands {
        Group("tag") {
            Command("create")
                .alias("add")
                .arg(String.self, named: "name")
                .arg(String.Consuming.self, named: "value")
                .execute { (event, name, value) -> AnyFuture in
                    guard let identifier = event.user.identifier else { return event.message.reply("Something went wrong") }
                    var updated = false
                    if let t = self.tags[name] {
                        // We already have a tag
                        guard t.createdBy.identifier == identifier else {
                            return event.message.reply("Unable to update tag \(t.name), you did not create it.")
                        }
                        updated = true
                    }
                    
                    let tag = Tag(name: name, value: value, createdBy: event.user, createdAt: Date())
                    self.tags[name] = tag
                    
                    return event.message.reply("Sucesfully \(updated ? "updated" : "created") tag \(tag.name)")
            }
            
            Command("delete")
                .alias("remove")
                .arg(String.self, named: "name")
                .execute { (event, name) -> AnyFuture in
                    guard let identifier = event.user.identifier, let tag = self.tags[name] else {
                        return event.message.reply("Unable to find tag.")
                    }
                    
                    guard tag.createdBy.identifier == identifier else {
                        return event.message.reply("You are only allowed to delete tags you created.")
                    }
                    
                    self.tags[tag.name] = nil
                    self.analytics[tag.name] = nil
                    return event.message.reply("Sucesfully deleted tag \(tag.name)")
            }
            
            Command("stats")
                .arg(String.self, named: "name")
                .execute { (event, name) -> AnyFuture in
                    guard let tag = self.tags[name], let stats = self.analytics[tag.name] else {
                        return event.message.reply("Unable to find tag.")
                    }
                    
                    let fmt = DateFormatter()
                    fmt.dateFormat = "EEEE, MMM d, yyyy 'at' HH:mm"
                    return event.message.reply("Tag \(tag.name) was created by \(tag.createdBy.mention) on \(fmt.string(from: tag.createdAt)). It's been used \(stats.count) times.")
            }
        }
    }
    
    var listeners: some EventListeners {
        Listeners {
            GlobalListener(Global.messageCreate) { event, message -> Void in
                let components = message.content.split(separator: " ")
                guard components.count == 1, let name = components.first.map(String.init), let tag = self.tags[name] else { return }
                
                var analytics = self.analytics[tag.name] ?? TagAnalytics()
                analytics.count += 1
                self.analytics[tag.name] = analytics
                
                message.reply(tag.value)
            }
        }
    }
}

struct TagAnalytics {
    var count: Int = 0
}

struct Tag {
    let name: String
    let value: String
    
    let createdBy: Userable
    let createdAt: Date
}
