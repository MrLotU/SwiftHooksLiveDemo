import SwiftHooks
import Discord
import NIO

final class CookiePlugin: Plugin {
    
    // Don't use dictionaries like this in production
    // They are not thread safe!
    var cookieDict: [Snowflake: Int] = [:]
    
    // Don't use dictionaries like this in production
    // They are not thread safe!
    var heistDict: [Snowflake: CookieHeistState] = [:]
    
    let yesEmoji = "green_tick:725427226920747028"
    let noEmoji = "red_tick:725427226962690209"

    var commands: some Commands {
        Group("cookie") {
            Command("give")
                .arg(Discord.User.self, named: "user")
                .arg(Int?.self, named: "amount")
                .execute { (event, user, amount) in
                    let amount = amount ?? 1
                    guard amount > 0 else {
                        return event.message.reply("You must give at least 1 cookie!")
                    }
                    
                    var cookies = self.cookieDict[user.id] ?? 0
                    cookies += amount
                    self.cookieDict[user.id] = cookies
                    
                    return event.message.reply("Gave \(user.mention) a cookie. They have a total of \(cookies) cookie(s) now.")
            }
            
            Command("eat")
                .arg(Int?.self, named: "amount")
                .execute { (event, amount) in
                    guard let user = event.user.discord else {
                        return event.message.reply("Unable to get user!")
                    }
                    let amount = amount ?? 1
                    guard amount > 0 else {
                        return event.message.reply("You must eat at least 1 cookie!")
                    }
                    
                    var cookies = self.cookieDict[user.id] ?? 0
                    if cookies >= amount {
                        cookies -= amount
                        self.cookieDict[user.id] = cookies
                        
                        return event.message.reply("Mmmmmm! Delicious. You now have \(cookies) cookie(s) left!")
                    } else {
                        return event.message.reply("You don't have enough cookies to eat \(amount). You only have \(cookies) cookie(s)")
                    }
            }
            
            Command("steal")
                .arg(Int.self, named: "amount")
                .arg(Discord.User.self, named: "victim")
                .execute { (event, amount, victim) in
                    guard let user = event.user.discord,
                          let message = event.message.discord else {
                            return event.message.reply("Unable to get user or message!")
                    }
                    
                    guard let userCookies = self.cookieDict[user.id],
                        userCookies >= 1 else {
                            return message.reply("You don't have enough cookies to proceed. You need at least 1 cookie.")
                    }
                    
                    // TODO: Steal!
                    return message
                        .reply("Are you sure you want to attempt to steal \(amount) of cookie(s) from \(victim.mention)")
                        .flatMap { (msg: Message) -> EventLoopFuture<Void> in
                            let state = CookieHeistState(stealer: user, victim: victim, amount: amount, message: message)
                            self.heistDict[msg.id] = state
                            return msg.addReaction(self.yesEmoji).flatMap {
                                msg.addReaction(self.noEmoji)
                            }
                    }
            }
        }
    }
    
    
    var listeners: some EventListeners {
        Listeners {
            Listener(Discord.messageReactionAdd) { event, reaction -> Void in
                guard let id = reaction.emoji.id,
                    let name = reaction.emoji.name,
                    let user = event.state.users[reaction.userId],
                    let state = self.heistDict[reaction.messageId],
                    user.id == state.stealer.id else { return }
                
                defer { self.heistDict[reaction.messageId] = nil }
                
                switch "\(name):\(id)" {
                case self.yesEmoji:
                    let chanceIndex = min(state.amount + 16, 100)
                    let chanceOfSuccess = Array((0...100).map { $0 * $0 }.reversed().map(Double.init).map {$0 / 10000})[chanceIndex]
                    
                    if Double.random(in: 0...1) < chanceOfSuccess {
                        let victimCookies = self.cookieDict[state.victim.id] ?? 0
                        var stealerCookies = self.cookieDict[state.stealer.id] ?? 0
                        
                        stealerCookies += state.amount
                        self.cookieDict[state.stealer.id] = stealerCookies
                        self.cookieDict[state.victim.id] = max(victimCookies - state.amount, 0)
                        state.message.reply("\(state.stealer.mention) success! Stole \(state.amount) cookies from \(state.victim.mention). You have \(stealerCookies) cookies now!")
                    } else {
                        let victimCookies = self.cookieDict[state.victim.id] ?? 0
                        let stealerCookies = self.cookieDict[state.stealer.id] ?? 0
                        
                        self.cookieDict[state.victim.id] = victimCookies + 1
                        self.cookieDict[state.stealer.id] = max(stealerCookies -  1, 0)
                        
                        state.message.reply("\(state.stealer.mention) failure! As punishment you had to pay \(state.victim.mention) 1 cookie!")
                    }
                    
                case self.noEmoji:
                    state.message.reply("Allright, cancelling heist plans!")
                default:
                    return
                }
            }
        }
    }
}

struct CookieHeistState {
    let stealer: Discord.User
    let victim: Discord.User
    let amount: Int
    let message: Discord.Message
}
