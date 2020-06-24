import SwiftHooks
import Discord

final class RolePlugin: Plugin {
    let roleDict: [String: Snowflake] = [
        "red": Snowflake(rawValue: 724194123342675998),
        "blue": Snowflake(rawValue: 724194147900325898)
    ]
    
    var commands: some Commands {
        Group("role") {
            Command("join")
                .arg(String.self, named: "role")
                .execute { (event, role) in
                    guard let roleId = self.roleDict[role], let userId = event.user.discord?.id, let guild = event.message.discord?.guild, let role = guild.roles[roleId], let member = guild.members[userId] else {
                        return event.message.reply("Role not found.")
                    }
                    
                    guard !member.roles.contains(role.id) else {
                        return event.message.reply("Unable to add role \(role.name). You already have it!")
                    }
                    
                    return member.addRole(role).flatMap {
                        return event.message.reply("Awesome. You now have the \(role.name) role.")
                    }
            }
            
            
            Command("leave")
                .arg(String.self, named: "role")
                .execute { (event, role) in
                    guard let roleId = self.roleDict[role], let userId = event.user.discord?.id, let guild = event.message.discord?.guild, let role = guild.roles[roleId], let member = guild.members[userId] else {
                        return event.message.reply("Role not found.")
                    }
                    
                    guard member.roles.contains(role.id) else {
                        return event.message.reply("Unable to remove role \(role.name). You don't have it!")
                    }
                    
                    return member.removeRole(role).flatMap {
                        return event.message.reply("Awesome. You no longer have the \(role.name) role.")
                    }
            }
            
            Command("assign")
                .arg(Discord.User.self, named: "user")
                .arg(String.self, named: "role")
                .check(IDChecker("188918216008007680", "yourUserId"))
                .execute { (event, user, role) in
                    guard let roleId = self.roleDict[role], let guild = event.message.discord?.guild, let role = guild.roles[roleId], let member = guild.members[user.id] else {
                        return event.message.reply("User or role not found.")
                    }
                    
                    guard !member.roles.contains(roleId) else {
                        return event.message.reply("Unable to add role \(role.name). User already has it!")
                    }
                    
                    return member.addRole(role).flatMap {
                        return event.message.reply("Awesome. Added the \(role.name) role to \(member.mention)")
                    }
            }
            
            Command("remove")
                .arg(Discord.User.self, named: "user")
                .arg(String.self, named: "role")
                .check(OwnerPermissionChecker())
                .execute { (event, user, role) -> AnyFuture in
                    guard let roleId = self.roleDict[role], let guild = event.message.discord?.guild, let role = guild.roles[roleId], let member = guild.members[user.id] else {
                        return event.message.reply("User or role not found.")
                    }
                    guard member.roles.contains(roleId) else {
                        return event.message.reply("Unable to remove role \(role.name). User doesn't have it.")
                    }
                    
                    return member.removeRole(role).flatMap {
                        return event.message.reply("Awesome. \(member.mention) no longer has the \(role.name) role.")
                    }
            }
        }
    }
}

struct OwnerPermissionChecker: CommandPermissionChecker {
    func check(_ user: Userable, canUse command: _ExecutableCommand, on event: CommandEvent) -> Bool {
        guard let user = user.discord, let guild = event.message.discord?.guild else { return false }
        return guild.ownerId == user.id
    }
}
