const {assert} = require("local-chai");
const {setupStarterPack} = require("./subTests/fixtures");
const {expectRevert} = require("local-utils");
const {privateKey} = require("./subTests/_testHelper");
const {signPurchaseMessage} = require("../../lib/purchaseMessageSigner");
const {getNamedAccounts} = require("@nomiclabs/buidler");

describe("PurchaseValidator", function () {
  let starterPack;
  let roles;
  let buyer;
  let Message;

  const TestMessage = {
    catalystIds: [0, 1, 2, 3],
    catalystQuantities: [1, 1, 1, 1],
    gemIds: [0, 1, 2, 3, 4],
    gemQuantities: [2, 2, 2, 2, 2],
    // @review !
    buyer: "",
    nonce: 0,
  };

  beforeEach(async function () {
    ({starterPackContract: starterPack} = await setupStarterPack());
    roles = await getNamedAccounts();
    buyer = roles.others[0];
    Message = {...message};
  });
  describe("Validation", function () {
    it("Purchase validator function exists", async function () {
      Message.buyer = roles.others[1];
      const dummySignature = signPurchaseMessage(privateKey, Message);
      assert.ok(
        await starterPack.isPurchaseValid(
          buyer,
          Message.catalystIds,
          Message.catalystQuantities,
          Message.gemIds,
          Message.gemQuantities,
          Message.nonce,
          signature
        )
      );
    });

    it("the order of catalystIds should't matter", async function () {
      Message.catalystIds = [2, 3, 0, 1];
      Message.gemQuantities = [0, 0, 1, 1, 0];
      assert.ok(
        await starterPack.isPurchaseValid(
          buyer,
          Message.catalystIds,
          Message.catalystQuantities,
          Message.gemIds,
          Message.gemQuantities,
          Message.nonce,
          signature
        )
      );

      Message.catalystIds = [3, 2, 1, 0];
      Message.catalystQuantities = [2, 1, 0, 3];
      Message.gemQuantities = [5, 2, 3, 1, 3];
      assert.ok(
        await starterPack.isPurchaseValid(
          buyer,
          Message.catalystIds,
          Message.catalystQuantities,
          Message.gemIds,
          Message.gemQuantities,
          Message.nonce + 1,
          signature
        )
      );
    });

    it("Should be possible to get the nonce for a buyer", async function () {
      // default queueId (0)
      let nonce = await starterPack.getNonceByBuyer(buyer, 0);
      assert.equal(nonce, 0);
    });

    it("Should be possible to get the signing wallet", async function () {
      const {starterPackContract: starterPack} = await setupStarterPack();
      const {backendMessageSigner} = await getNamedAccounts();
      const wallet = await starterPack.getSigningWallet();
      assert.equal(wallet, backendMessageSigner);
    });

    it("Should be possible for Admin to update the signing wallet", async function () {
      const {starterPackContractAsAdmin: starterPackAsAdmin} = await setupStarterPack();
      const newSigner = roles.others[1];
      await starterPackAsAdmin.updateSigningWallet(newSigner);
      const wallet = await starterPackAsAdmin.getSigningWallet();
      assert.equal(wallet, newSigner);
    });
  });

  describe("Failures", function () {
    it("should fail if the nonce is re-used", async function () {
      ({starterPackContract: starterPack} = await setupStarterPack());
      assert.ok(
        await starterPack.isPurchaseValid(
          buyer,
          Message.catalystIds,
          Message.catalystQuantities,
          Message.gemIds,
          Message.gemQuantities,
          Message.nonce,
          signature
        )
      );

      await expectRevert(
        starterPack.isPurchaseValid(
          buyer,
          Message.catalystIds,
          Message.catalystQuantities,
          Message.gemIds,
          Message.gemQuantities,
          Message.nonce,
          signature
        ),
        "INVALID_NONCE"
      );
    });

    it("should fail if too many gems are requested", async function () {
      ({starterPackContract: starterPack} = await setupStarterPack());
      Message.catalystQuantities = [1, 1, 1, 1];
      // total gems allowed is max 10
      Message.gemQuantities = [3, 2, 4, 2, 3];
      await expectRevert(
        starterPack.isPurchaseValid(
          buyer,
          Message.catalystIds,
          Message.catalystQuantities,
          Message.gemIds,
          Message.gemQuantities,
          Message.nonce,
          signature
        ),
        "INVALID_GEMS"
      );
    });
    it("Should fail if anyone but Admin tries to update signing wallet", async function () {
      const {starterPackContract: starterPack} = await setupStarterPack();
      const newSigner = roles.others[0];
      await expectRevert(starterPack.updateSigningWallet(newSigner), "SENDER_NOT_ADMIN");
    });
  });

  it("should fail if the nonce is re-used", async function () {
    ({starterPackContract: starterPack} = await setupStarterPack());
    Message.buyer = roles.others[1];
    const dummySignature = signPurchaseMessage(privateKey, Message);
    assert.ok(
      await starterPack.isPurchaseValid(
        Message.buyer,
        Message.catalystIds,
        Message.catalystQuantities,
        Message.gemIds,
        Message.gemQuantities,
        Message.buyer,
        Message.nonce,
        dummySignature
      )
    );

    await expectRevert(
      starterPack.isPurchaseValid(
        Message.buyer,
        Message.catalystIds,
        Message.catalystQuantities,
        Message.gemIds,
        Message.gemQuantities,
        Message.buyer,
        Message.nonce,
        dummySignature
      ),
      "INVALID_NONCE"
    );
  });

  it("should fail if too many gems are requested", async function () {
    ({starterPackContract: starterPack} = await setupStarterPack());
    Message.catalystQuantities = [1, 1, 1, 1];
    // total gems allowed is max 10
    Message.gemQuantities = [3, 2, 4, 2, 3];
    Message.buyer = roles.others[1];
    const dummySignature = signPurchaseMessage(privateKey, Message);
    await expectRevert(
      starterPack.isPurchaseValid(
        Message.buyer,
        Message.catalystIds,
        Message.catalystQuantities,
        Message.gemIds,
        Message.gemQuantities,
        Message.buyer,
        Message.nonce,
        dummySignature
      ),
      "INVALID_GEMS"
    );
  });
  it("Should fail if anyone but Admin tries to update signing wallet", async function () {
    const {starterPackContract: starterPack} = await setupStarterPack();
    const newSigner = roles.others[0];
    await expectRevert(starterPack.updateSigningWallet(newSigner), "SENDER_NOT_ADMIN");
  });
});
