import IC "./ic";
import Map "mo:base/HashMap";
import Int "mo:base/Nat";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";

actor class (principals: [Principal], limit: Nat) = self {
    // create_canister, install_code, start_canister, stop_canister, delete_canister
    type WalletMS = {
        principals: [Principal];
        limit: Nat;
    };

    let walletms : WalletMS = {
        principals = principals;
        limit = limit;
    };

    type CanisterOprs = {#create; #install; #start; #stop; #delete};

    private func match_opr(canister_opr: CanisterOprs) : Nat {
        switch (canister_opr) {
            case (#create) {return 0};
            case (#install) {return 1};
            case (#start) {return 2};
            case (#stop) {return 3};
            case (#delete) {return 4};
        };
        return 5;
        
    };
    
    type EntryKey = {
        canister_name: Text;
        canister_opr: CanisterOprs;
    };

    type Entry = {
        var canister_id: ?Principal;
        principals: Map.HashMap<Principal, Bool>;
    };

    private func entry_equal(entrya: EntryKey, entryb: EntryKey) : Bool {
        return (entrya.canister_name == entryb.canister_name and entrya.canister_opr == entryb.canister_opr);
    };
    
    private func entry_hash(entry: EntryKey) : Hash.Hash {
        let text = entry.canister_name#Int.toText(match_opr(entry.canister_opr));
        Text.hash(text);
    };

    let canisterebook = Map.HashMap<EntryKey, Entry>(0, entry_equal, entry_hash);
    let canisterIdx = Buffer.Buffer<Entry>(0);
    
    

    private func do_opr(entry_key: EntryKey): Bool {
        let canister = canisterebook.get(entry_key);
        switch (canister) {
            case (null) {
                return false;
            };
            case (?canister) {
                var cnt = 0;
                for (principal in walletms.principals.vals()) {
                    let voted = canister.principals.get(principal);
                    switch (voted) {
                        case (null) {};
                        case (?voted) {
                            if (voted) {
                                cnt += 1;
                            }
                        }
                    };
                };
                return cnt == walletms.limit;
            }
        };
    };

    public query func get_canister_id(canister_name: Text): async ?IC.canister_id {
        let entry_key : EntryKey = {
            canister_name = canister_name;
            canister_opr = #create;
        };
        let canister = canisterebook.get(entry_key);
        switch (canister) {
            case (null) {
                return null;
            };
            case (?canister) {
                return canister.canister_id;
            }
        };
    };

    private func new_vote_event(entry_key: EntryKey, caller: Principal) : Entry {
        let entry : Entry = {
            var canister_id = null;
            principals = Map.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);
        };
        for ( principal in walletms.principals.vals() ) {
            entry.principals.put(principal, false);
        };
        entry.principals.put(caller, true);
        canisterebook.put(entry_key, entry);
        return entry;
    };

    public shared(msg) func create_canister(canister_name: Text) : async ?IC.canister_id {
        let entry_key : EntryKey = {
            canister_name = canister_name;
            canister_opr = #create;
        };
        
        let canister = canisterebook.get(entry_key);
        var canister_real : Entry = {
            var canister_id = null;
            principals = Map.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);
        };
        switch (canister) {
            case (null) {
                var caller = msg.caller;
                canister_real := new_vote_event(entry_key, caller);
            };
            case (?canister) {
                canister_real := canister;
                canister_real.principals.put(msg.caller, true);
            }
        };

        if ( not do_opr(entry_key) ) {
            return null;
        };

        let n = principals.size();
        let settings = {
            freezing_threshold = null;
            controllers = ?[msg.caller];
            memory_allocation = null;
            compute_allocation = null;
        };
        let ic : IC.Self = actor("aaaaa-aa");
        let result = await ic.create_canister({ settings = ?settings });
        canister_real.canister_id := ?result.canister_id;
        canisterebook.put(entry_key, canister_real);
        return ?result.canister_id;
    };



    public shared(msg) func install_code(
        canister_name: Text, 
        arg: [Nat8], 
        wasm_module: IC.wasm_module, 
        mode: { #reinstall; #upgrade; #install }) : async ?Bool {

        let canister_id = await get_canister_id(canister_name);
        switch (canister_id) {
            case (null) {
                return ?false;
            };
            case (?canister_id) {
                let entry_key : EntryKey = {
                    canister_name = canister_name;
                    canister_opr = #install;
                };
                
                let canister = canisterebook.get(entry_key);
                var canister_real : Entry = {
                    var canister_id = null;
                    principals = Map.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);
                };
                switch (canister) {
                    case (null) {
                        var caller = msg.caller;
                        canister_real := new_vote_event(entry_key, caller);
                        canister_real.canister_id := ?canister_id;
                    };
                    case (?canister) {
                        canister_real.principals.put(msg.caller, true);
                    };
                };

                if ( not do_opr(entry_key) ) {
                    return null;
                };
                let n = principals.size();

                let ic : IC.Self = actor("aaaaa-aa");
                await ic.install_code({ 
                    arg = arg;
                    wasm_module = wasm_module;
                    mode = mode;
                    canister_id = canister_id;
                });
                canisterebook.put(entry_key, canister_real);
                return ?true;
            }
        }
    };

    public shared(msg) func start_canister(canister_name: Text) : async (?Bool) {
        let canister_id = await get_canister_id(canister_name);
        switch (canister_id) {
            case (null) {
                return ?false;
            };
            case (?canister_id) {
                let entry_key : EntryKey = {
                    canister_name = canister_name;
                    canister_opr = #start;
                };
                
                let canister = canisterebook.get(entry_key);
                var canister_real : Entry = {
                    var canister_id = null;
                    principals = Map.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);
                };
                switch (canister) {
                    case (null) {
                        var caller = msg.caller;
                        canister_real := new_vote_event(entry_key, caller);
                        canister_real.canister_id := ?canister_id;
                    };
                    case (?canister) {
                        canister_real.principals.put(msg.caller, true);
                    };
                };

                if ( not do_opr(entry_key) ) {
                    return null;
                };
                let n = principals.size();

                let ic : IC.Self = actor("aaaaa-aa");
                await ic.start_canister({ canister_id = canister_id; });
                canisterebook.put(entry_key, canister_real);
                return ?true;
            }
        }
    };

    public shared(msg) func stop_canister(canister_name: Text) : async (?Bool) {
        let canister_id = await get_canister_id(canister_name);
        switch (canister_id) {
            case (null) {
                return ?false;
            };
            case (?canister_id) {
                let entry_key : EntryKey = {
                    canister_name = canister_name;
                    canister_opr = #stop;
                };
                
                let canister = canisterebook.get(entry_key);
                var canister_real : Entry = {
                    var canister_id = null;
                    principals = Map.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);
                };
                switch (canister) {
                    case (null) {
                        var caller = msg.caller;
                        canister_real := new_vote_event(entry_key, caller);
                        canister_real.canister_id := ?canister_id;
                    };
                    case (?canister) {
                        canister_real.principals.put(msg.caller, true);
                    };
                };

                if ( not do_opr(entry_key) ) {
                    return null;
                };
                let n = principals.size();

                let ic : IC.Self = actor("aaaaa-aa");
                await ic.stop_canister({ canister_id = canister_id; });
                canisterebook.put(entry_key, canister_real);
                return ?true;
            }
        }
    };

    public shared(msg) func delete_canister(canister_name: Text) : async (?Bool) {
        let canister_id = await get_canister_id(canister_name);
        switch (canister_id) {
            case (null) {
                return ?false;
            };
            case (?canister_id) {
                let entry_key : EntryKey = {
                    canister_name = canister_name;
                    canister_opr = #delete;
                };
                
                let canister = canisterebook.get(entry_key);
                var canister_real : Entry = {
                    var canister_id = null;
                    principals = Map.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);
                };
                switch (canister) {
                    case (null) {
                        var caller = msg.caller;
                        canister_real := new_vote_event(entry_key, caller);
                        canister_real.canister_id := ?canister_id;
                    };
                    case (?canister) {
                        canister_real.principals.put(msg.caller, true);
                    };
                };

                if ( not do_opr(entry_key) ) {
                    return null;
                };
                let n = principals.size();

                let ic : IC.Self = actor("aaaaa-aa");
                await ic.delete_canister({ canister_id = canister_id; });
                canisterebook.put(entry_key, canister_real);
                return ?true;
            }
        }
    };
}