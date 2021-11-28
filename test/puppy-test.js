const { expect } = require("chai");

describe("Ponzi and wETH contract", function () {
  let puppy;
  let weth;
  let owner;
  let addr1;
  let addr2;
  let addrs;
  let bene = "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720"; //acc10

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    let wethfactory = await ethers.getContractFactory("WETH");
    weth = await wethfactory.deploy();

    await weth.transfer(addr1.address, "1000000000000000000");
    await weth.transfer(addr2.address, "1000000000000000000");
    for(let i = 0; i < 5; i++) {
      await weth.transfer(addrs[i].address, "1000000000000000000");
    }

    let puppyfactory = await ethers.getContractFactory("Puppies");
    puppy = await puppyfactory.deploy("Ponzi Puppies", "PP", weth.address);
  });

  it("WETH balance", async function () {
    const ownerBalance = await weth.balanceOf(owner.address);
    expect(ownerBalance).not.equal('0');
  });

  it("Owns no puppies", async function () {
    const puppybalance = await puppy.balanceOf(addr2.address);
    expect(puppybalance).to.equal('0');
  });

  describe("Stripped Stuff", function () {
    it("transferFrom disabled", async function () {
      await weth.connect(addr1).approve(puppy.address, "100000000000")
      await puppy.connect(addr1).mint("Hugo", "0x123124");
      await expect(puppy.connect(addr1).transferFrom(addr1.address, addr2.address, "1")).to.be.reverted;
    })


  })

  describe("Metadata tests", function () {

   it("Owner can set baseURL", async function () {
     const puppyurl = await puppy.setBaseURI("yolo/");
     expect(puppyurl).to.not.equal('0');
   });

   it("Non-Owner cannot set baseURL", async function () {
    //const puppyurl = await puppy.connect(addr1).setBaseURI("yolo/");
    //await expect(puppyurl).eventually.to.be.rejectedWith('Error');
    await expect(puppy.connect(addr1).setBaseURI("yolo/")).to.be.reverted;
  });

  it("token URI can be retrieved", async function () {
    const setty = await puppy.setBaseURI("https://ponzipuppies.com/api/v1/");
    await weth.connect(addr2).approve(puppy.address, "100000000000")
    await puppy.connect(addr2).mint("Hugo", "0x5438f469e00f0a6b83008f6553fe6ebb9794244dd4d65ca7b7765846424df08a");
    const lastid = await puppy.totalSupply();
    const puppyurl = await puppy.tokenURI(lastid);
    expect(puppyurl).to.equal('https://ponzipuppies.com/api/v1/?dna=0x5438f469e00f0a6b83008f6553fe6ebb9794244dd4d65ca7b7765846424df08a&name=Hugo');
  });

  it("name is correct", async function () {
    const res = await puppy.name();
    expect(res).to.equal('Ponzi Puppies');
  });

  it("symbol is correct", async function () {
    const res = await puppy.symbol();
    expect(res).to.equal('PP');
  });
})

describe("Minting tests", function () {

  it("Anybody can mint dog", async function () {
    await weth.connect(addr2).approve(puppy.address, "100000000000")
    const res = await weth.allowance(addr2.address, puppy.address)
    expect(res).to.not.equal('0');
    await puppy.connect(addr2).mint("Hugo", "0x123124");
  });

  it("minting fee goes to correct account", async function () {
    await weth.connect(addr2).approve(puppy.address, "100000000000")
    const res = await weth.allowance(addr2.address, puppy.address)
    expect(res).to.not.equal('0');
    const bal1 = await weth.balanceOf(bene)
    await puppy.connect(addr2).mint("Hugo", "0x123124");
    const bal2 = await weth.balanceOf(bene)
    expect(bal1).to.not.equal(bal2)
  });

  it("Anybody can mint max. 3 dogs", async function () {
    await weth.connect(addr2).approve(puppy.address, "1000000000000")
    await puppy.connect(addr2).mint("Hugo", "0x123124");
    await puppy.connect(addr2).mint("Hugo2", "0x1231245");
    await puppy.connect(addr2).mint("Hugo3", "0x1231246");
    await expect(puppy.connect(addr2).mint("Hugo5", "0x3231246")).to.be.reverted;
  });

  it("Cannot mint same name twice", async function () {
    await weth.connect(addr2).approve(puppy.address, "10000000000000")
    await puppy.connect(addr2).mint("Hugo", "0x1231242343246");
    await expect(puppy.connect(addr2).mint("Hugo", "0x3446")).to.be.reverted;
  });

  it("Cannot mint same dna twice", async function () {
    await weth.connect(addr2).approve(puppy.address, "10000000000000")
    await puppy.connect(addr2).mint("Hugo23234", "0x1231242343246");
    await expect(puppy.connect(addr2).mint("Hugo", "0x1231242343246")).to.be.reverted;
  });

  it("after five mints correct owners and totals", async function () {
    await weth.connect(addr2).approve(puppy.address, "1000000000000")
    await weth.connect(addr1).approve(puppy.address, "1000000000000")
    let mfee = [0,0,0,0,0,0]
    mfee[0] = await puppy.mintingfee();
    await puppy.connect(addr1).mint("Hugo", "0x123124");
    mfee[1] = await puppy.mintingfee();
    await puppy.connect(addr1).mint("Hugo2", "0x1231245");
    mfee[2] = await puppy.mintingfee();
    await puppy.connect(addr1).mint("Hugo3", "0x1231246");
    mfee[3] = await puppy.mintingfee();
    await puppy.connect(addr2).mint("Hugo4", "0x1231247");
    mfee[4] = await puppy.mintingfee();
    await puppy.connect(addr2).mint("Hugo5", "0x1231248");
    mfee[5] = await puppy.mintingfee();
    const tot = await puppy.totalSupply()
    expect(tot).to.equal("26", "Total Supply neq 26");

    let infee = ethers.BigNumber.from("1000000000")
    for(let i = 0; i < 6; i++) {
      expect(mfee[i]).to.equal(infee)
      infee = infee.mul(101).div(100)
    }

    expect(await puppy.balanceOf(addr1.address)).to.equal("3", "Addr1 balance neq 3")
    expect(await puppy.balanceOf(addr2.address)).to.equal("2", "Addr2 balance neq 2")

    expect(await puppy.ownerOf("22")).to.equal(addr1.address, "owner of 22 neq addr1")
    expect(await puppy.ownerOf("23")).to.equal(addr1.address, "owner of 23 neq addr1")
    expect(await puppy.ownerOf("24")).to.equal(addr1.address, "owner of 24 neq addr1")
    expect(await puppy.ownerOf("25")).to.equal(addr2.address, "owner of 25 neq addr2")
    expect(await puppy.ownerOf("26")).to.equal(addr2.address, "owner of 26 neq addr2")
    
  });

})

describe("Pausing", function () { 

  it("no minting", async function () {
    await puppy.pauseContract()
    await weth.connect(addr1).approve(puppy.address, "10000000000000")
    await expect(puppy.connect(addr1).mint("Hugo23234", "0x1231242343246")).to.be.reverted;
  })

  it("no setPrice", async function () {
    
    await weth.connect(addr1).approve(puppy.address, "10000000000000")
    await puppy.connect(addr1).mint("Hugo23234", "0x1231242343246")
    await puppy.pauseContract()
    await expect(puppy.connect(addr1).setPrice(1, "10000")).to.be.reverted;
  })

  it("no buynow", async function () {
    await weth.connect(addr1).approve(puppy.address, "10000000000000")
    await weth.connect(addr2).approve(puppy.address, "10000000000000")
    await puppy.connect(addr1).mint("Hugo23234", "0x1231242343246")
    const lastid = await puppy.totalSupply();
    await puppy.connect(addr1).setPrice(lastid, "10000")
    await puppy.pauseContract()
    await expect(puppy.connect(addr2).buynow(lastid, "10000")).to.be.reverted;
  })

  it("pause unpause minting", async function () {
    await puppy.pauseContract()
    await weth.connect(addr1).approve(puppy.address, "10000000000000")
    await expect(puppy.connect(addr1).mint("Hugo23234", "0x1231242343246")).to.be.reverted;
    await puppy.unpauseContract()
    await puppy.connect(addr1).mint("Hugo23234", "0x1231242343246")
    const owny = await puppy.balanceOf(addr1.address)
    expect(owny).to.be.equal("1")
  })

})

describe("Pricing and Buying", function () { 

  it("owner can setPrice", async function () {
    await weth.connect(addr1).approve(puppy.address, "10000000000000")
    await puppy.connect(addr1).mint("Hugo23234", "0x1231242343246");
    const lastid = await puppy.totalSupply();
    const owny = await puppy.ownerOf(lastid)
    expect(owny).to.equal(addr1.address)
    await puppy.connect(addr1).setPrice(lastid, "10000000");
    const price = await puppy.getPrice(lastid)
    expect(price).to.not.equal('0')
  })

  it("non-owner cannot setPrice", async function () {
    await weth.connect(addr1).approve(puppy.address, "10000000000000")
    await puppy.connect(addr1).mint("Hugo23234", "0x1231242343246");
    const lastid = await puppy.totalSupply();
    await expect(puppy.connect(addr2).setPrice(lastid, "10000000")).to.be.reverted;
  })

  it("owner setPrice & buy flow", async function () {
    await weth.connect(addr1).approve(puppy.address, "10000000000000")
    await weth.connect(addr2).approve(puppy.address, "10000000000000")
    await puppy.connect(addr1).mint("Hugo23234", "0x1231242343246");
    const lastid = await puppy.totalSupply();
    await puppy.connect(addr1).setPrice(lastid, "10000000");
    const ow1 = await puppy.ownerOf(lastid)
    expect(ow1).to.equal(addr1.address)
    await puppy.connect(addr2).buynow(lastid, "10000000");
    const ow2 = await puppy.ownerOf(lastid)
    expect(ow2).to.equal(addr2.address)
  })
})

describe("data fetching", function() {

  it("get all puppies", async function() {
    const pups = await puppy.getAllPuppies()
    expect(pups.length).to.equal(21, "Puppi length mismatch")
  })

})

describe("Ownership multiple", function() {

  it("12 owners, history len 10", async function () {
    await weth.connect(addr1).approve(puppy.address, "10000000000000")
    await weth.connect(addr2).approve(puppy.address, "10000000000000")
    await puppy.connect(addr1).mint("Hugo23234", "0x1231242343246");
    const lastid = await puppy.totalSupply();
    //addr1 is owner 1
    for(let i = 0; i< 6; i++) {
      await puppy.connect(addr1).setPrice(lastid, "12000000");
      await puppy.connect(addr2).buynow(lastid, "12000000");
      await puppy.connect(addr2).setPrice(lastid, "11000000");
      await puppy.connect(addr1).buynow(lastid, "11000000");
    }
    const arr = await puppy.getHistory(lastid)
    expect(arr.length).to.equal(10);
  })

  it("royalties payment", async function () {
    await weth.connect(addr1).approve(puppy.address, "10000000000000")
    await weth.connect(addr2).approve(puppy.address, "10000000000000")
    await weth.connect(addrs[0]).approve(puppy.address, "10000000000000")
    await weth.connect(addrs[1]).approve(puppy.address, "10000000000000")
    await weth.connect(addrs[2]).approve(puppy.address, "10000000000000")

    await puppy.connect(addr1).mint("Hugo23234", "0x1231242343246");
    const lastid = await puppy.totalSupply();

    await puppy.connect(addr1).setPrice(lastid, "12000000");
    await puppy.connect(addr2).buynow(lastid, "12000000");

    await puppy.connect(addr2).setPrice(lastid, "11000000");
    await puppy.connect(addrs[0]).buynow(lastid, "11000000");

    await puppy.connect(addrs[0]).setPrice(lastid, "11000000");
    await puppy.connect(addrs[1]).buynow(lastid, "11000000");

    const bal0_a = await weth.balanceOf(addr1.address)
    const bal1_a = await weth.balanceOf(addr2.address)
    const bal2_a = await weth.balanceOf(addrs[0].address)
    const bal3_a = await weth.balanceOf(addrs[1].address)
    const bal4_a = await weth.balanceOf(addrs[2].address)
    const bal5_a = await weth.balanceOf(bene)

    const pricy = "1000000"
    await puppy.connect(addrs[1]).setPrice(lastid, pricy);
    await puppy.connect(addrs[2]).buynow(lastid, pricy);

    const bigpricy = ethers.BigNumber.from(pricy)
    const baseline = bigpricy.mul(25).div(1000)

    const fees = baseline.add(baseline >> 1).add(baseline >> 2).add(bigpricy.div(100))
    const exp0 = bal0_a.add(baseline)
    const exp1 = bal1_a.add(baseline >> 1)
    const exp2 = bal2_a.add(baseline >> 2)
    const exp3 = bal3_a.add(bigpricy).sub(fees)//seller
    const exp4 = bal4_a.sub(bigpricy) //buyer
    const exp5 = bal5_a.add(bigpricy.div(100))

    const bal0_b = await weth.balanceOf(addr1.address);
    const bal1_b = await weth.balanceOf(addr2.address);
    const bal2_b = await weth.balanceOf(addrs[0].address);
    const bal3_b = await weth.balanceOf(addrs[1].address);
    const bal4_b = await weth.balanceOf(addrs[2].address);
    const bal5_b = await weth.balanceOf(bene);

    expect(bal0_b).to.be.equal(exp0)
    expect(bal1_b).to.be.equal(exp1)
    expect(bal2_b).to.be.equal(exp2)
    expect(bal3_b).to.be.equal(exp3)
    expect(bal4_b).to.be.equal(exp4)
    expect(bal5_b).to.be.equal(exp5)
    


  })


})


});
