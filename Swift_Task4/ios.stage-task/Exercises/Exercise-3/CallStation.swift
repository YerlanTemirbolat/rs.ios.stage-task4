import Foundation

final class CallStation {
    var myUsers: [User] = []
    var myCalls: [Call] = []
}

extension CallStation: Station {

    func users() -> [User] {
        return myUsers
    }
    
    func add(user: User) {
        if !self.myUsers.contains(user) {
            self.myUsers.append(user)
        }
    }
    
    func remove(user: User) {
        let index = myUsers.firstIndex(where: {$0.id == user.id})
        if index != nil {
            myUsers.remove(at: index!)
        }
    }

    func execute(action: CallAction) -> CallID? {

        switch action {
        case .start(from: let incomingUser, to: let outgoingUser):

            if !myUsers.contains(incomingUser) && !myUsers.contains(outgoingUser) {
                return nil
            } else if !myUsers.contains(outgoingUser) {
                let errorUUID = UUID.init()
                let myCall = (Call(id: errorUUID, incomingUser: incomingUser, outgoingUser: outgoingUser, status: .ended(reason: .error)))
                myCalls.append(myCall)
                return errorUUID
            }

            if self.currentCall(user: outgoingUser) != nil {
                let busyUUID = UUID.init()
                let myCall = (Call(id: busyUUID, incomingUser: incomingUser, outgoingUser: outgoingUser, status: .ended(reason: .userBusy)))
                myCalls.append(myCall)
                return busyUUID
            }

            let myId = UUID.init()
            let myCall = (Call(id: myId, incomingUser: incomingUser, outgoingUser: outgoingUser, status: .calling))
            self.myCalls.append(myCall)

            return myId

        case .answer(from: let incomingUser):

            // && $0.status == .calling
            let myId = myCalls.first(where: {$0.outgoingUser.id == incomingUser.id})?.id

            let callIndex = self.myCalls.firstIndex(where: {$0.id == myId && $0.status == .calling})

            guard let index = callIndex else {
                return nil
            }

            guard myUsers.contains(myCalls[index].outgoingUser) else {
                
                myCalls[index].status = .ended(reason: .error)
                return nil
            }

            myCalls[index].status = .talk


            return myId

        case .end(from: let outgoingUser):

            let myId = calls(user: outgoingUser).first?.id
            
            let cancelIndex = self.myCalls.firstIndex(where: {$0.id == myId && $0.status == .calling})
            if cancelIndex != nil {
                myCalls[cancelIndex!].status = .ended(reason: .cancel)
            }

            let endIndex = self.myCalls.firstIndex(where: {$0.id == myId && $0.status == .talk})
            if endIndex != nil {
                myCalls[endIndex!].status = .ended(reason: .end)
            }

            return myId
        }
    }
    
    func calls() -> [Call] {
        myCalls
    }
    
    func calls(user: User) -> [Call] {
        let calls = myCalls.filter { call in
            call.incomingUser.id == user.id || call.outgoingUser.id == user.id
        }
        return calls
    }
    
    func call(id: CallID) -> Call? {
        let myCall = myCalls.filter { itemCall in
            itemCall.id == id
        }
        return myCall.first ?? nil
    }
    
    func currentCall(user: User) -> Call? {
        let call = myCalls.filter { call in
            (call.incomingUser.id == user.id || call.outgoingUser.id == user.id) &&
                (call.status == .calling || call.status == .talk)
        }
        return call.first
    }
}
