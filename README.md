

# deploy 

```bash
npx hardhat run scripts/01-deploy.ts --network sepolia
```


- a 发起 对 b 的求婚。a 可以发起多个求婚，但是同时只能有一个生效，第二次发起会把第一次发起的记录给清掉。
- b 可以看到所有对他发起的求婚的地址和信息，并选择其中一个地址进行确认。
- a 和 b 会创建一个 Attestation，之后 a 和 b 都不能再发起求婚或者确认求婚。