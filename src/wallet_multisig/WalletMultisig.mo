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
import Iter "mo:base/Iter";
import Array "mo:base/Array";
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
    type CanisterOprs = {#create; #install; #start; #stop; #uninstall; #delete; #update};

    // 操作参数类型, 目前只写了 create_canister 的参数
    type install_orgs = {
        arg : [Nat8];
        wasm_module : IC.wasm_module;
        mode : { #reinstall; #upgrade; #install };
        canister_id : IC.canister_id;
    };
    type update_orgs = {
        canister_settings : IC.canister_settings;
        canister_id : IC.canister_id;
    };
    type OprArgs = {
        
        create: ?IC.canister_settings;
        install: ?install_orgs;
        start: ?Principal;
        stop: ?Principal;
        uninstall: ?Principal;
        delete: ?Principal;
        update: ?update_orgs;
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

    type CanisterStatus = {#created; #installed; #started; #stopped; #uninstalled; #deleted; #updated};
    type CanisterInfo = {
        flag: Bool;
        status: CanisterStatus;
    };

    var proposal_idx = 0;
    let proposal_book : Map.HashMap<Nat, Proposal> = Map.HashMap<Nat, Proposal>(0, Nat.equal, Nat32.fromNat);
    let canister_book : Map.HashMap<Principal, CanisterInfo> = Map.HashMap<Principal, CanisterInfo>(0, Principal.equal, Principal.hash);

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
                    if (voted) {
                        cnt += 1;
                        if (cnt > walletms.limit) {
                            return false;
                        }
                    };
                    
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
                let voted = vote_proposal.principals.get(msg.caller);
                switch (voted) {
                    case (null) {};
                    case (?voted) {return false};
                };
                vote_proposal.principals.put(msg.caller, true);
                if (should_exec(vote_proposal)) { // 判读是否应该执行提案
                    let result_exec = await proposal_exec(vote_proposal);
                    if (not result_exec.flag) {
                        vote_proposal.principals.put(msg.caller, false);
                        return false;
                    };
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
                            if (voted) {
                                principals.add(principal);
                            };
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
                let canister_id = await canister_create(vote_proposal.args);
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
                let result = await canister_install(vote_proposal.args);
                return {
                    flag = result.0;
                    canister_id = result.1;
                };
                
            };
            case (#start) {
                let result = await canister_start(vote_proposal.args);
                return {
                    flag = result.0;
                    canister_id = result.1;
                };
            };
            case (#stop) {
                let result = await canister_stop(vote_proposal.args);
                return {
                    flag = result.0;
                    canister_id = result.1;
                };
            };
            case (#delete) {
                let result = await canister_delete(vote_proposal.args);
                return {
                    flag = result.0;
                    canister_id = result.1;
                };
            };
            case (#update) {
                let result = await canister_update(vote_proposal.args);
                return {
                    flag = result.0;
                    canister_id = result.1;
                };
            };
            case (#uninstall) {
                let result = await canister_uninstall(vote_proposal.args);
                return {
                    flag = result.0;
                    canister_id = result.1;
                };
            };
        };
        return {canister_id = null; flag = true;};
    };

    private func canister_create(args: OprArgs) : async ?IC.canister_id {
        let settings = args.create;
        switch (settings) {
            case (null) {
                return null;
            };
            case (?settings) {
                let ic : IC.Self = actor("aaaaa-aa");
                Cycles.add(1_000_000_000_000);
                let result = await ic.create_canister({ settings = ?settings });
                canister_book.put(
                    result.canister_id, 
                    {
                        flag = true;
                        status = #created;
                    }
                );
                return ?result.canister_id;
            }
        };
    };

    private func canister_install(args: OprArgs) : async (Bool, ?Principal) {
        let settings = args.install;
        switch (settings) {
            case (null) {
                return (false, null);
            };
            case (?settings) {
                let canister = canister_book.get(settings.canister_id);
                switch (canister) {
                    case (null) {return (false, null);};
                    case (?canister) {
                        let ic : IC.Self = actor("aaaaa-aa");
                        await ic.install_code({ 
                            arg = settings.arg;
                            wasm_module = settings.wasm_module;
                            mode = settings.mode;
                            canister_id = settings.canister_id;
                        });
                        canister_book.put(
                            settings.canister_id, 
                            {
                                flag = true;
                                status = #installed;
                            }
                        );
                        return (true, ?settings.canister_id);
                    }
                }
            }
        };
    };

    private func canister_update(args: OprArgs) : async (Bool, ?Principal) {
        let settings = args.update;
        switch (settings) {
            case (null) {
                return (false, null);
            };
            case (?settings) {
                let canister = canister_book.get(settings.canister_id);
                switch (canister) {
                    case (null) {return (false, null);};
                    case (?canister) {
                        let ic : IC.Self = actor("aaaaa-aa");
                        await ic.update_settings({ 
                            settings = settings.canister_settings;
                            canister_id = settings.canister_id;
                        });
                        canister_book.put(
                            settings.canister_id, 
                            {
                                flag = true;
                                status = #updated;
                            }
                        );
                        return (true, ?settings.canister_id);
                    }
                }
            }
        };
    };

    private func canister_start(args: OprArgs) : async (Bool, ?Principal) {
        let canister_id = args.start;
        switch (canister_id) {
            case (null) {
                return (false, null);
            };
            case (?canister_id) {
                let canister = canister_book.get(canister_id);
                switch (canister) {
                    case (null) {return (false, null);};
                    case (?canister) {
                        let ic : IC.Self = actor("aaaaa-aa");
                        await ic.start_canister({ 
                            canister_id = canister_id;
                        });
                        canister_book.put(
                            canister_id, 
                            {
                                flag = true;
                                status = #started;
                            }
                        );
                        return (true, ?canister_id);
                    }
                }
            }
        };
    };

    private func canister_stop(args: OprArgs) : async (Bool, ?Principal) {
        let canister_id = args.stop;
        switch (canister_id) {
            case (null) {
                return (false, null);
            };
            case (?canister_id) {
                let canister = canister_book.get(canister_id);
                switch (canister) {
                    case (null) {return (false, null);};
                    case (?canister) {
                        let ic : IC.Self = actor("aaaaa-aa");
                        await ic.stop_canister({ 
                            canister_id = canister_id;
                        });
                        canister_book.put(
                            canister_id, 
                            {
                                flag = true;
                                status = #stopped;
                            }
                        );
                        return (true, ?canister_id);
                    }
                }
            }
        };
    };

    private func canister_delete(args: OprArgs) : async (Bool, ?Principal) {
        let canister_id = args.stop;
        switch (canister_id) {
            case (null) {
                return (false, null);
            };
            case (?canister_id) {
                let canister = canister_book.get(canister_id);
                switch (canister) {
                    case (null) {return (false, null);};
                    case (?canister) {
                        let ic : IC.Self = actor("aaaaa-aa");
                        await ic.delete_canister({ 
                            canister_id = canister_id;
                        });
                        canister_book.put(
                            canister_id, 
                            {
                                flag = true;
                                status = #deleted;
                            }
                        );
                        return (true, ?canister_id);
                    }
                }
            }
        };
    };

    private func canister_uninstall(args: OprArgs) : async (Bool, ?Principal) {
        let canister_id = args.uninstall;
        switch (canister_id) {
            case (null) {
                return (false, null);
            };
            case (?canister_id) {
                let canister = canister_book.get(canister_id);
                switch (canister) {
                    case (null) {return (false, null);};
                    case (?canister) {
                        let ic : IC.Self = actor("aaaaa-aa");
                        await ic.uninstall_code({ 
                            canister_id = canister_id;
                        });
                        canister_book.put(
                            canister_id, 
                            {
                                flag = true;
                                status = #uninstalled;
                            }
                        );
                        return (true, ?canister_id);
                    }
                }
            }
        };
    };

    type ReturnProposal = {
        idx: Nat;
        canister_id: ?Principal;
        operation: CanisterOprs;
        args: OprArgs;
    };
    public func getAllProposals() : async [?ReturnProposal] {
        return Array.tabulate<?ReturnProposal>(
            proposal_idx+1,
            func (i: Nat) : ?ReturnProposal {
                let proposal = proposal_book.get(i);
                switch (proposal) {
                    case (null) {return null;};
                    case (?proposal) {
                        return ?{
                            idx = proposal.idx;
                            canister_id: ?Principal = proposal.canister_id;
                            operation = proposal.operation;
                            args = proposal.args;
                        }
                    };
                };
            }
        );
    };
    type ReturnCanister = {
        principal: Principal;
        info: ?CanisterInfo;
    };  
    public func getAllCanisters() : async [?ReturnCanister] {
        let canisters = Buffer.Buffer<?ReturnCanister>(0);
        for (key in canister_book.keys()) {
            canisters.add(?{
                principal : Principal = key;
                info : ?CanisterInfo = canister_book.get(key);
            });
        };
        return canisters.toArray();
    };

    public func getAllMembers() : async [Principal] {
        return walletms.principals;
    };

    public func greet(name : Text) : async Text {
        return "Hello, " # name # "!";
    };

    public shared (msg) func whoami() : async Principal {
        msg.caller
    };

}