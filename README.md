# ICP advanced lesson 04

## Problem
### 作业：
在第3课作业的基础上，实现以下的功能：
1. 对被限权的 canister 进行常规操作时 (比如 install_code)，并不立即执行，改为发起提案，只有提案通过后才执行 。（3 分）
2. 简单的前端界面，允许查看当前的提案，已经部署的 canister 列表（包括 id, 当前状态等），小组成员名单等。 （1 分）
3. 在前端整合 Internet Identity 登录，登录后看到自己的 Principal ID 。（1 分）
本次课程作业先实现后端的限权操作，不涉及前端提交，或者时前端投票的具体操作。

### 要求：
1. 至少实现一种限权操作，比如 install_code，如果额外实现了其它限权操作，适当加分。
2. 在 install_code 的处理过程中，计算 Wasm 的 sha256 值，并作为提案的一部分（这样小组成员才能确认是否要投赞成还是否决）。

### 命令
```bash
dfx start --clean
dfx deploy --argument '( vec { principal "rsqv3-7dkj5-yvrcl-l2bkm-vkvuj-tdync-my6md-ob6uj-ah3bu-dpk3x-gqe"}, 1 )'
dfx canister call wallet_multisig proposal_issue '( null , variant {create}, record { create = opt record {freezing_threshold = null; controllers = opt vec { principal "22ylo-gaaaa-aaaao-aag3a-cai" }; memory_allocation = null; compute_allocation = null} })'
dfx canister call wallet_multisig proposal_vote '( 1 )'
dfx canister call wallet_multisig proposal_view '( 1 )'
# 主网
dfx deploy --network=ic --with-cycles=4000000000000 --argument '( vec { principal "rsqv3-7dkj5-yvrcl-l2bkm-vkvuj-tdync-my6md-ob6uj-ah3bu-dpk3x-gqe"}, 1 )'
```

### 注意

执行过程中发生 cycles 不足的情况，那么是不会回滚的，出错之前写入的内容还是有效的

### 网址
- https://25zn2-lyaaa-aaaao-aag3q-cai.ic0.app/