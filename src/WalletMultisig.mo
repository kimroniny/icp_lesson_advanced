import IC "./ic";
import Map "mo:base/HashMap";
import Int "mo:base/Nat";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";

// m 就是 principals 的大小，所以不需要把 m 也传进去，只需要传 limit 即可
actor class (principals: [Principal], limit: Nat) = self {
    type WalletMS = {
        principals: [Principal];
        limit: Nat;
    };

    let walletms : WalletMS = {
        principals = principals;
        limit = limit;
    };

    // 支持的操作, 根据题目要求, 只实现了 create
    type CanisterOprs = {#create; #install; #start; #stop; #delete; #upgrade};

    // 操作参数类型, 目前只写了 create_canister 的参数
    type OprArgs = {
        
        create_canister: ?IC.canister_settings;
    };

    // 提案类型
    type Proposal = {
        idx: Nat;
        principals: Map.HashMap<Principal, Bool>;
        var canister_id: ?Principal;
        operation: CanisterOprs;
        args: OprArgs;
    };

    // 提案的执行结果, 主要是为了兼容 create_canister 会有返回结果 canister_id
    type ResultExec = {
        canister_id: ?Principal;
        flag: Bool;
    };

    var proposal_idx = 0;
    let proposal_book : Map.HashMap<Nat, Proposal> = Map.HashMap<Nat, Proposal>(0, Nat.equal, Nat32.fromNat);
    let canister_book : Map.HashMap<Principal, Bool> = Map.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);

    // 检查提案操作的调用者是否是 principals 中的成员
    private func check_sender(sender: Principal) : Bool {
        for ( principal in walletms.principals.vals() ) {
            if (Principal.equal(principal, sender)) {
                return true;
            }
        };
        return false;
    };

    // 检查是否应该执行提案
    private func should_exec(proposal: Proposal) : Bool {
        var cnt = 0;
        for ( principal in walletms.principals.vals() ) {
            let voted = proposal.principals.get(principal);
            switch (voted) {
                case (null) {
                    
                };
                case (?voted) {
                    cnt += 1;
                    if (cnt > walletms.limit) {
                        return false;
                    }
                }
            }
        };
        return cnt == walletms.limit; // 只有当 voted_number == limit 的时候才可以执行, 如果大于则说明已经执行过了
    };

    // 发起提案
    public shared(msg) func proposal_issue(canister_id: ?Principal, operation: CanisterOprs, args: OprArgs) : async Nat {
        assert check_sender(msg.caller);
        var canister_id2:?Principal = canister_id;
        proposal_idx += 1;
        let principals = Map.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);
        proposal_book.put(
            proposal_idx,
            {
                idx = proposal_idx;
                var canister_id = canister_id2;
                principals = principals;
                operation = operation;
                args = args;
            }
        );
        return proposal_idx;
    };

    // 给提案投票
    public shared(msg) func proposal_vote(vote_proposal_id: Nat) : async Bool {
        assert check_sender(msg.caller);
        var vote_proposal = proposal_book.get(vote_proposal_id);
        switch (vote_proposal) {
            case (null) {
                return false;
            };
            case (?vote_proposal) {
                vote_proposal.principals.put(msg.caller, true);
                if (should_exec(vote_proposal)) { // 判读是否应该执行提案
                    let result_exec = await proposal_exec(vote_proposal);
                    if (not result_exec.flag) {return false;};
                    let canister_id = result_exec.canister_id;
                    switch (canister_id) {
                        case (null) {
                        };
                        case (?canister_id) {
                            vote_proposal.canister_id := ?canister_id;
                        }
                    }
                };
                proposal_book.put(
                    vote_proposal_id,
                    vote_proposal
                );
                return true;
                
            }
        }
    };

    public query func proposal_view(proposal_id: Nat) :async (?[Principal], ?Principal, ?OprArgs) {
        let principals = Buffer.Buffer<Principal>(0);
        let proposal = proposal_book.get(proposal_id);
        switch (proposal) {
            case (null) {
                return (null, null, null);
            };
            case (?proposal) {
                for (principal in walletms.principals.vals()) {
                    let voted = proposal.principals.get(principal);
                    switch (voted) {
                        case (null) {};
                        case (?voted) {
                            principals.add(principal);
                        }
                    };
                };
                return (?principals.toArray(), proposal.canister_id, ?proposal.args);
            }
        }
        
    };
    
    // 执行提案
    private func proposal_exec(vote_proposal: Proposal) : async ResultExec {
        switch (vote_proposal.operation) {
            case (#create) {
                let canister_id = await create_canister(vote_proposal.args);
                switch (canister_id) {
                    case (null) {
                        return {canister_id = null; flag = false;};        
                    };
                    case (?canister_id) {
                        return {canister_id = ?canister_id; flag = true;};        
                    }
                };
            };
            case (#install) {
                return {canister_id = null; flag = true;};
            };
            case (#start) {
                return {canister_id = null; flag = true;};
            };
            case (#stop) {
                return {canister_id = null; flag = true;};
            };
            case (#delete) {
                return {canister_id = null; flag = true;};
            };
            case (#upgrade) {
                return {canister_id = null; flag = true;};
            };
        };
        return {canister_id = null; flag = true;};
    };

    private func create_canister(args: OprArgs) : async ?IC.canister_id {
        let settings = args.create_canister;
        switch (settings) {
            case (null) {
                return null;
            };
            case (?settings) {
                let ic : IC.Self = actor("aaaaa-aa");
                Cycles.add(1_000_000_000_000);
                let result = await ic.create_canister({ settings = ?settings });
                canister_book.put(result.canister_id, true);
                return ?result.canister_id;
            }
        };
    };

}