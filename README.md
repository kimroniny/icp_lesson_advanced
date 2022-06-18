# ICP advanced lesson 05

## Problem
### 作业：
在第4课作业的基础上，实现以下的功能（一个简单但是功能自洽的 DAO 系统）（5分）：
1. 前端对 canister 进行操作，包括 create_canister, install_code, start_canister, stop_canister, delete_canister。对被限权的 Canister 的操作时，会发起新提案。
2. 前端可以上传 Wasm 代码，用于 install_code。
3. 前端发起提案和投票的操作。
4. 支持增加和删除小组成员的提案。
5. 让多人钱包接管自己（对钱包本身的操作，比如升级，需要走提案流程）

### 命令
```bash
dfx start --clean
dfx deploy --network=ic --with-cycles=5000000000000 --argument '(1, vec { principal "rsqv3-7dkj5-yvrcl-l2bkm-vkvuj-tdync-my6md-ob6uj-ah3bu-dpk3x-gqe"})'
dfx canister --network=ic call wallet_multisig propose '(variant {createCanister}, null, null)'
dfx canister --network=ic call wallet_multisig approve '(1)'
```

### 注意

执行过程中发生 cycles 不足的情况，那么是不会回滚的，出错之前写入的内容还是有效的

### 网址
- https://u7ufb-3yaaa-aaaao-aah3q-cai.ic0.app/