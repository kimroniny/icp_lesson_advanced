# ICP advanced lesson 03

## Problem
### 作业：
在第2课作业的基础上，实现以下的功能：
1. 用 Actor Class 参数来初始化 M, N, 以及最开始的小组成员（principal id)。（1分）
2. 允许发起提案，比如对某个被多人钱包管理的 canister 限制权限。（1分）
3. 统计小组成员对提案的投票（同意或否决），并根据投票结果执行决议。（2分）
4. 在主网部署，并调试通过。（1 分）
本次课程作业先实现基本的提案功能，不涉及具体限权的操作。

### 要求：
1. 设计发起提案 (propose) 和对提案进行投票 (vote) 的接口。
2. 实现以下两种提案：
- 开始对某个指定的 canister 限权。
- 解除对某个指定的 canister 限权。
3. 在调用 IC Management Canister 的时候，给出足够的 cycle。

### 命令
```bash
dfx start --clean
dfx deploy --argument '( vec { principal "rsqv3-7dkj5-yvrcl-l2bkm-vkvuj-tdync-my6md-ob6uj-ah3bu-dpk3x-gqe"}, 1 )'
dfx canister call wallet_multisig proposal_issue '( null , variant {create}, record {})'
dfx canister call wallet_multisig proposal_vote '( 1 )'
dfx canister call wallet_multisig proposal_view '( 1 )'
dfx canister call wallet_multisig proposal_issue '( null , variant {create}, record { create_canister = opt record { null; opt vec { principal "rrkah-fqaaa-aaaaa-aaaaq-cai" }; null; null} })'
dfx canister call wallet_multisig proposal_issue '( null , variant {create}, record { create_canister = opt record {freezing_threshold = null; controllers = opt vec { principal "rrkah-fqaaa-aaaaa-aaaaq-cai" }; memory_allocation = null; compute_allocation = null} })'
# 主网
dfx deploy --network=ic --with-cycles=4000000000000 --argument '( vec { principal "rsqv3-7dkj5-yvrcl-l2bkm-vkvuj-tdync-my6md-ob6uj-ah3bu-dpk3x-gqe"}, 1 )'
```

### 网址
- https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/