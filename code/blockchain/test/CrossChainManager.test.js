const { expect } = require("chai");
const { deploy } = require("../scripts/deploy");

describe("CrossChainManager", () => {
  let manager;
  
  before(async () => {
    const contracts = await deploy();
    manager = contracts.manager;
  });

  it("Should create positions with valid allocations", async () => {
    const tx = await manager.createPosition([5000, 5000], "0x");
    await expect(tx).to.emit(manager, "PositionCreated");
  });
});