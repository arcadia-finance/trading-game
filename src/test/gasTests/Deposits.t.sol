// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.10;

import "../../../lib/ds-test/src/test.sol";
import "../../../lib/forge-std/src/stdlib.sol";
import "../../../lib/forge-std/src/console.sol";
import "../../../lib/forge-std/src/Vm.sol";

import "../../Factory.sol";
import "../../Proxy.sol";
import "../../Vault.sol";
import "../../mockups/ERC20SolmateMock.sol";
import "../../mockups/ERC721SolmateMock.sol";
import "../../mockups/ERC1155SolmateMock.sol";
import "../../Stable.sol";
import "../../AssetRegistry/MainRegistry.sol";
import "../../AssetRegistry/FloorERC721SubRegistry.sol";
import "../../AssetRegistry/StandardERC20SubRegistry.sol";
import "../../AssetRegistry/floorERC1155SubRegistry.sol";
import "../../InterestRateModule.sol";
import "../../Liquidator.sol";
import "../../OracleHub.sol";
import "../../mockups/SimplifiedChainlinkOracle.sol";
import "../../utils/Constants.sol";

contract gasDeposits is DSTest {
  using stdStorage for StdStorage;

  Vm private vm = Vm(HEVM_ADDRESS);  
  StdStorage private stdstore;

  Factory private factory;
  Vault private vault;
  Vault private proxy;
  address private proxyAddr;
  ERC20Mock private eth;
  ERC20Mock private snx;
  ERC20Mock private link;
  ERC20Mock private safemoon;
  ERC721Mock private bayc;
  ERC721Mock private mayc;
  ERC721Mock private dickButs;
  ERC20Mock private wbayc;
  ERC20Mock private wmayc;
  ERC1155Mock private interleave;
  ERC1155Mock private genericStoreFront;
  OracleHub private oracleHub;
  SimplifiedChainlinkOracle private oracleEthToUsd;
  SimplifiedChainlinkOracle private oracleLinkToUsd;
  SimplifiedChainlinkOracle private oracleSnxToEth;
  SimplifiedChainlinkOracle private oracleWbaycToEth;
  SimplifiedChainlinkOracle private oracleWmaycToUsd;
  SimplifiedChainlinkOracle private oracleInterleaveToEth;
  SimplifiedChainlinkOracle private oracleGenericStoreFrontToEth;
  MainRegistry private mainRegistry;
  StandardERC20Registry private standardERC20Registry;
  FloorERC721SubRegistry private floorERC721SubRegistry;
  FloorERC1155SubRegistry private floorERC1155SubRegistry;
  InterestRateModule private interestRateModule;
  Stable private stable;
  Liquidator private liquidator;

  address private creatorAddress = address(1);
  address private tokenCreatorAddress = address(2);
  address private oracleOwner = address(3);
  address private unprivilegedAddress = address(4);
  address private stakeContract = address(5);
  address private vaultOwner = address(6);


  uint256 rateEthToUsd = 3000 * 10 ** Constants.oracleEthToUsdDecimals;
  uint256 rateLinkToUsd = 20 * 10 ** Constants.oracleLinkToUsdDecimals;
  uint256 rateSnxToEth = 1600000000000000;
  uint256 rateWbaycToEth = 85 * 10 ** Constants.oracleWbaycToEthDecimals;
  uint256 rateWmaycToUsd = 50000 * 10 ** Constants.oracleWmaycToUsdDecimals;
  uint256 rateInterleaveToEth = 1 * 10 ** (Constants.oracleInterleaveToEthDecimals - 2);
  uint256 rateGenericStoreFrontToEth = 1 * 10 ** (8);

  address[] public oracleEthToUsdArr = new address[](1);
  address[] public oracleLinkToUsdArr = new address[](1);
  address[] public oracleSnxToEthEthToUsd = new address[](2);
  address[] public oracleWbaycToEthEthToUsd = new address[](2);
  address[] public oracleWmaycToUsdArr = new address[](1);
  address[] public oracleInterleaveToEthEthToUsd = new address[](2);
  address[] public oracleGenericStoreFrontToEthEthToUsd = new address[](2);

  // EVENTS
  event Transfer(address indexed from, address indexed to, uint256 amount);

  //this is a before
  constructor() {
    vm.startPrank(tokenCreatorAddress);

    eth = new ERC20Mock("ETH Mock", "mETH", uint8(Constants.ethDecimals));
    eth.mint(tokenCreatorAddress, 200000 * 10**Constants.ethDecimals);

    snx = new ERC20Mock("SNX Mock", "mSNX", uint8(Constants.snxDecimals));
    snx.mint(tokenCreatorAddress, 200000 * 10**Constants.snxDecimals);

    link = new ERC20Mock("LINK Mock", "mLINK", uint8(Constants.linkDecimals));
    link.mint(tokenCreatorAddress, 200000 * 10**Constants.linkDecimals);

    safemoon = new ERC20Mock("Safemoon Mock", "mSFMN", uint8(Constants.safemoonDecimals));
    safemoon.mint(tokenCreatorAddress, 200000 * 10**Constants.safemoonDecimals);

    bayc = new ERC721Mock("BAYC Mock", "mBAYC");
    bayc.mint(tokenCreatorAddress, 0);
    bayc.mint(tokenCreatorAddress, 1);
    bayc.mint(tokenCreatorAddress, 2);
    bayc.mint(tokenCreatorAddress, 3);
    bayc.mint(tokenCreatorAddress, 4);
    bayc.mint(tokenCreatorAddress, 5);
    bayc.mint(tokenCreatorAddress, 6);
    bayc.mint(tokenCreatorAddress, 7);
    bayc.mint(tokenCreatorAddress, 8);
    bayc.mint(tokenCreatorAddress, 9);
    bayc.mint(tokenCreatorAddress, 10);
    bayc.mint(tokenCreatorAddress, 11);
    bayc.mint(tokenCreatorAddress, 12);

    mayc = new ERC721Mock("MAYC Mock", "mMAYC");
    mayc.mint(tokenCreatorAddress, 0);
    mayc.mint(tokenCreatorAddress, 1);
    mayc.mint(tokenCreatorAddress, 2);
    mayc.mint(tokenCreatorAddress, 3);
    mayc.mint(tokenCreatorAddress, 4);
    mayc.mint(tokenCreatorAddress, 5);
    mayc.mint(tokenCreatorAddress, 6);
    mayc.mint(tokenCreatorAddress, 7);
    mayc.mint(tokenCreatorAddress, 8);
    mayc.mint(tokenCreatorAddress, 9);

    dickButs = new ERC721Mock("DickButs Mock", "mDICK");
    dickButs.mint(tokenCreatorAddress, 0);
    dickButs.mint(tokenCreatorAddress, 1);
    dickButs.mint(tokenCreatorAddress, 2);

    wbayc = new ERC20Mock("wBAYC Mock", "mwBAYC", uint8(Constants.wbaycDecimals));
    wbayc.mint(tokenCreatorAddress, 100000 * 10**Constants.wbaycDecimals);

    interleave = new ERC1155Mock("Interleave Mock", "mInterleave");
    interleave.mint(tokenCreatorAddress, 1, 100000);
    interleave.mint(tokenCreatorAddress, 2, 100000);
    interleave.mint(tokenCreatorAddress, 3, 100000);
    interleave.mint(tokenCreatorAddress, 4, 100000);
    interleave.mint(tokenCreatorAddress, 5, 100000);

    genericStoreFront = new ERC1155Mock("Generic Storefront Mock", "mGSM");
    genericStoreFront.mint(tokenCreatorAddress, 1, 100000);
    genericStoreFront.mint(tokenCreatorAddress, 2, 100000);
    genericStoreFront.mint(tokenCreatorAddress, 3, 100000);
    genericStoreFront.mint(tokenCreatorAddress, 4, 100000);
    genericStoreFront.mint(tokenCreatorAddress, 5, 100000);

    vm.stopPrank();

    vm.prank(creatorAddress);
    oracleHub = new OracleHub();

    vm.startPrank(oracleOwner);
    oracleEthToUsd = new SimplifiedChainlinkOracle(uint8(Constants.oracleEthToUsdDecimals), "ETH / USD");
    oracleLinkToUsd = new SimplifiedChainlinkOracle(uint8(Constants.oracleLinkToUsdDecimals), "LINK / USD");
    oracleSnxToEth = new SimplifiedChainlinkOracle(uint8(Constants.oracleSnxToEthDecimals), "SNX / ETH");
    oracleWbaycToEth = new SimplifiedChainlinkOracle(uint8(Constants.oracleWbaycToEthDecimals), "WBAYC / ETH");
    oracleWmaycToUsd = new SimplifiedChainlinkOracle(uint8(Constants.oracleWmaycToUsdDecimals), "WMAYC / USD");
    oracleInterleaveToEth = new SimplifiedChainlinkOracle(uint8(Constants.oracleInterleaveToEthDecimals), "INTERLEAVE / ETH");
    oracleGenericStoreFrontToEth = new SimplifiedChainlinkOracle(uint8(10), "GenericStoreFront / ETH");

    oracleEthToUsd.setAnswer(int256(rateEthToUsd));
    oracleLinkToUsd.setAnswer(int256(rateLinkToUsd));
    oracleSnxToEth.setAnswer(int256(rateSnxToEth));
    oracleWbaycToEth.setAnswer(int256(rateWbaycToEth));
    oracleWmaycToUsd.setAnswer(int256(rateWmaycToUsd));
    oracleGenericStoreFrontToEth.setAnswer(int256(rateGenericStoreFrontToEth));
    vm.stopPrank();

    vm.startPrank(creatorAddress);
    oracleHub.addOracle(OracleHub.OracleInformation({oracleUnit:uint64(Constants.oracleEthToUsdUnit), baseAssetNumeraire: 0, quoteAsset:'ETH', baseAsset:'USD', oracleAddress:address(oracleEthToUsd), quoteAssetAddress:address(eth), baseAssetIsNumeraire: true}));
    oracleHub.addOracle(OracleHub.OracleInformation({oracleUnit:uint64(Constants.oracleLinkToUsdUnit), baseAssetNumeraire: 0, quoteAsset:'LINK', baseAsset:'USD', oracleAddress:address(oracleLinkToUsd), quoteAssetAddress:address(link), baseAssetIsNumeraire: true}));
    oracleHub.addOracle(OracleHub.OracleInformation({oracleUnit:uint64(Constants.oracleSnxToEthUnit), baseAssetNumeraire: 1, quoteAsset:'SNX', baseAsset:'ETH', oracleAddress:address(oracleSnxToEth), quoteAssetAddress:address(snx), baseAssetIsNumeraire: true}));
    oracleHub.addOracle(OracleHub.OracleInformation({oracleUnit:uint64(Constants.oracleWbaycToEthUnit), baseAssetNumeraire: 1, quoteAsset:'WBAYC', baseAsset:'ETH', oracleAddress:address(oracleWbaycToEth), quoteAssetAddress:address(wbayc), baseAssetIsNumeraire: true}));
    oracleHub.addOracle(OracleHub.OracleInformation({oracleUnit:uint64(Constants.oracleWmaycToUsdUnit), baseAssetNumeraire: 0, quoteAsset:'WMAYC', baseAsset:'USD', oracleAddress:address(oracleWmaycToUsd), quoteAssetAddress:address(wmayc), baseAssetIsNumeraire: true}));
    oracleHub.addOracle(OracleHub.OracleInformation({oracleUnit:uint64(Constants.oracleInterleaveToEthUnit), baseAssetNumeraire: 1, quoteAsset:'INTERLEAVE', baseAsset:'ETH', oracleAddress:address(oracleInterleaveToEth), quoteAssetAddress:address(interleave), baseAssetIsNumeraire: true}));
    oracleHub.addOracle(OracleHub.OracleInformation({oracleUnit:uint64(10**10), baseAssetNumeraire: 1, quoteAsset:'GenericStoreFront', baseAsset:'ETH', oracleAddress:address(oracleGenericStoreFrontToEth), quoteAssetAddress:address(genericStoreFront), baseAssetIsNumeraire: true}));
    vm.stopPrank();

    vm.startPrank(tokenCreatorAddress);
    eth.transfer(vaultOwner, 100000 * 10 ** Constants.ethDecimals);
    link.transfer(vaultOwner, 100000 * 10 ** Constants.linkDecimals);
    snx.transfer(vaultOwner, 100000 * 10 ** Constants.snxDecimals);
    safemoon.transfer(vaultOwner, 100000 * 10 ** Constants.safemoonDecimals);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 0);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 1);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 2);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 3);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 4);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 5);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 6);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 7);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 8);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 9);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 10);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 11);
    bayc.transferFrom(tokenCreatorAddress, vaultOwner, 12);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 0);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 1);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 2);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 3);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 4);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 5);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 6);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 7);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 8);
    mayc.transferFrom(tokenCreatorAddress, vaultOwner, 9);
    dickButs.transferFrom(tokenCreatorAddress, vaultOwner, 0);
    interleave.safeTransferFrom(tokenCreatorAddress, vaultOwner, 1, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    interleave.safeTransferFrom(tokenCreatorAddress, vaultOwner, 2, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    interleave.safeTransferFrom(tokenCreatorAddress, vaultOwner, 3, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    interleave.safeTransferFrom(tokenCreatorAddress, vaultOwner, 4, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    interleave.safeTransferFrom(tokenCreatorAddress, vaultOwner, 5, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    genericStoreFront.safeTransferFrom(tokenCreatorAddress, vaultOwner, 1, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    genericStoreFront.safeTransferFrom(tokenCreatorAddress, vaultOwner, 2, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    genericStoreFront.safeTransferFrom(tokenCreatorAddress, vaultOwner, 3, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    genericStoreFront.safeTransferFrom(tokenCreatorAddress, vaultOwner, 4, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    genericStoreFront.safeTransferFrom(tokenCreatorAddress, vaultOwner, 5, 100000, '0x0000000000000000000000000000000000000000000000000000000000000000');
    eth.transfer(unprivilegedAddress, 1000 * 10 ** Constants.ethDecimals);
    vm.stopPrank();

    vm.startPrank(creatorAddress);
    interestRateModule = new InterestRateModule();
    interestRateModule.setBaseInterestRate(5 * 10 ** 16);
    vm.stopPrank();

   vm.startPrank(tokenCreatorAddress);
    stable = new Stable("Arcadia Stable Mock", "masUSD", uint8(Constants.stableDecimals), 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000);
    vm.stopPrank();

    oracleEthToUsdArr[0] = address(oracleEthToUsd);

    oracleLinkToUsdArr[0] = address(oracleLinkToUsd);

    oracleSnxToEthEthToUsd[0] = address(oracleSnxToEth);
    oracleSnxToEthEthToUsd[1] = address(oracleEthToUsd);

    oracleWbaycToEthEthToUsd[0] = address(oracleWbaycToEth);
    oracleWbaycToEthEthToUsd[1] = address(oracleEthToUsd);

    oracleWmaycToUsdArr[0] = address(oracleWmaycToUsd);

    oracleInterleaveToEthEthToUsd[0] = address(oracleInterleaveToEth);
    oracleInterleaveToEthEthToUsd[1] = address(oracleEthToUsd);

    oracleGenericStoreFrontToEthEthToUsd[0] = address(oracleGenericStoreFrontToEth);
    oracleGenericStoreFrontToEthEthToUsd[1] = address(oracleEthToUsd);
  }

  //this is a before each
  function setUp() public {

    vm.startPrank(creatorAddress);
    mainRegistry = new MainRegistry(MainRegistry.NumeraireInformation({numeraireToUsdOracleUnit:0, assetAddress:0x0000000000000000000000000000000000000000, numeraireToUsdOracle:0x0000000000000000000000000000000000000000, numeraireLabel:'USD', numeraireUnit:1}));
    uint256[] memory emptyList = new uint256[](0);
    mainRegistry.addNumeraire(MainRegistry.NumeraireInformation({numeraireToUsdOracleUnit:uint64(10**Constants.oracleEthToUsdDecimals), assetAddress:address(eth), numeraireToUsdOracle:address(oracleEthToUsd), numeraireLabel:'ETH', numeraireUnit:uint64(10**Constants.ethDecimals)}), emptyList);

    standardERC20Registry = new StandardERC20Registry(address(mainRegistry), address(oracleHub));
    floorERC721SubRegistry = new FloorERC721SubRegistry(address(mainRegistry), address(oracleHub));
    floorERC1155SubRegistry = new FloorERC1155SubRegistry(address(mainRegistry), address(oracleHub));

    mainRegistry.addSubRegistry(address(standardERC20Registry));
    mainRegistry.addSubRegistry(address(floorERC721SubRegistry));
    mainRegistry.addSubRegistry(address(floorERC1155SubRegistry));

    uint256[] memory assetCreditRatings = new uint256[](2);
    assetCreditRatings[0] = 0;
    assetCreditRatings[1] = 0;

    standardERC20Registry.setAssetInformation(StandardERC20Registry.AssetInformation({oracleAddresses: oracleEthToUsdArr, assetUnit: uint64(10**Constants.ethDecimals), assetAddress: address(eth)}), assetCreditRatings);
    standardERC20Registry.setAssetInformation(StandardERC20Registry.AssetInformation({oracleAddresses: oracleLinkToUsdArr, assetUnit: uint64(10**Constants.linkDecimals), assetAddress: address(link)}), assetCreditRatings);
    standardERC20Registry.setAssetInformation(StandardERC20Registry.AssetInformation({oracleAddresses: oracleSnxToEthEthToUsd, assetUnit: uint64(10**Constants.snxDecimals), assetAddress: address(snx)}), assetCreditRatings);

    floorERC721SubRegistry.setAssetInformation(FloorERC721SubRegistry.AssetInformation({oracleAddresses: oracleWbaycToEthEthToUsd, idRangeStart:0, idRangeEnd:type(uint256).max, assetAddress: address(bayc)}), assetCreditRatings);
    floorERC721SubRegistry.setAssetInformation(FloorERC721SubRegistry.AssetInformation({oracleAddresses: oracleWmaycToUsdArr, idRangeStart:0, idRangeEnd:type(uint256).max, assetAddress: address(mayc)}), assetCreditRatings);
    floorERC1155SubRegistry.setAssetInformation(FloorERC1155SubRegistry.AssetInformation({oracleAddresses: oracleInterleaveToEthEthToUsd, id:1, assetAddress: address(interleave)}), assetCreditRatings);
    floorERC1155SubRegistry.setAssetInformation(FloorERC1155SubRegistry.AssetInformation({oracleAddresses: oracleGenericStoreFrontToEthEthToUsd, id:1, assetAddress: address(genericStoreFront)}), assetCreditRatings);

    liquidator = new Liquidator(0x0000000000000000000000000000000000000000, address(mainRegistry), address(stable));
    vm.stopPrank();

    vm.startPrank(vaultOwner);
    vault = new Vault();
    stable.transfer(address(0), stable.balanceOf(vaultOwner));
    vm.stopPrank();

    vm.startPrank(creatorAddress);
    factory = new Factory();
    factory.setVaultInfo(1, address(mainRegistry), address(vault), address(stable), stakeContract, address(interestRateModule));
    factory.setVaultVersion(1);
    factory.setLiquidator(address(liquidator));
    liquidator.setFactory(address(factory));
    mainRegistry.setFactory(address(factory));
    vm.stopPrank();

    vm.startPrank(tokenCreatorAddress);
    stable.setLiquidator(address(liquidator));
    stable.setFactory(address(factory));
    vm.stopPrank();

    vm.prank(vaultOwner);
    proxyAddr = factory.createVault(uint256(keccak256(abi.encodeWithSignature("doRandom(uint256,uint256,bytes32)", block.timestamp, block.number, blockhash(block.number)))));
    proxy = Vault(proxyAddr);

    vm.startPrank(oracleOwner);
    oracleEthToUsd.setAnswer(int256(rateEthToUsd));
    oracleLinkToUsd.setAnswer(int256(rateLinkToUsd));
    oracleSnxToEth.setAnswer(int256(rateSnxToEth));
    oracleWbaycToEth.setAnswer(int256(rateWbaycToEth));
    oracleWmaycToUsd.setAnswer(int256(rateWmaycToUsd));
    oracleInterleaveToEth.setAnswer(int256(rateInterleaveToEth));
    vm.stopPrank();

    vm.roll(1); //increase block for random salt

    vm.prank(tokenCreatorAddress);
    eth.mint(vaultOwner, 1e18);

    vm.startPrank(vaultOwner);
    bayc.setApprovalForAll(address(proxy), true);
    mayc.setApprovalForAll(address(proxy), true);
    dickButs.setApprovalForAll(address(proxy), true);
    interleave.setApprovalForAll(address(proxy), true);
    genericStoreFront.setApprovalForAll(address(proxy), true);
    eth.approve(address(proxy), type(uint256).max);
    link.approve(address(proxy), type(uint256).max);
    snx.approve(address(proxy), type(uint256).max);
    safemoon.approve(address(proxy), type(uint256).max);
    stable.approve(address(proxy), type(uint256).max);
    stable.approve(address(liquidator), type(uint256).max);
    vm.stopPrank();

    vm.startPrank(vaultOwner);

  }

  function test1_1_ERC20() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](1);
    assetAddresses[0] = address(eth);

    assetIds = new uint256[](1);
    assetIds[0] = 0;

    assetAmounts = new uint256[](1);
    assetAmounts[0] = 1e18;

    assetTypes = new uint256[](1);
    assetTypes[0] = 0;
    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test2_2_ERC20s() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](2);
    assetAddresses[0] = address(eth);
    assetAddresses[1] = address(link);

    assetIds = new uint256[](2);
    assetIds[0] = 0;
    assetIds[1] = 0;

    assetAmounts = new uint256[](2);
    assetAmounts[0] = 10**Constants.ethDecimals;
    assetAmounts[1] = 10**Constants.linkDecimals;

    assetTypes = new uint256[](2);
    assetTypes[0] = 0;
    assetTypes[1] = 0;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test3_3_ERC20s() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](3);
    assetAddresses[0] = address(eth);
    assetAddresses[1] = address(link);
    assetAddresses[2] = address(snx);

    assetIds = new uint256[](3);
    assetIds[0] = 0;
    assetIds[1] = 0;
    assetIds[2] = 0;

    assetAmounts = new uint256[](3);
    assetAmounts[0] = 10**Constants.ethDecimals;
    assetAmounts[1] = 10**Constants.linkDecimals;
    assetAmounts[2] = 10**Constants.snxDecimals;

    assetTypes = new uint256[](3);
    assetTypes[0] = 0;
    assetTypes[1] = 0;
    assetTypes[2] = 0;
    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test4_1_ERC721() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](1);
    assetAddresses[0] = address(bayc);

    assetIds = new uint256[](1);
    assetIds[0] = 1;

    assetAmounts = new uint256[](1);
    assetAmounts[0] = 1;

    assetTypes = new uint256[](1);
    assetTypes[0] = 1;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test5_2_same_ERC721() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](2);
    assetAddresses[0] = address(bayc);
    assetAddresses[1] = address(bayc);

    assetIds = new uint256[](2);
    assetIds[0] = 2;
    assetIds[1] = 3;

    assetAmounts = new uint256[](2);
    assetAmounts[0] = 1;
    assetAmounts[1] = 1;

    assetTypes = new uint256[](2);
    assetTypes[0] = 1;
    assetTypes[1] = 1;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test6_2_diff_ERC721() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](2);
    assetAddresses[0] = address(bayc);
    assetAddresses[1] = address(mayc);

    assetIds = new uint256[](2);
    assetIds[0] = 4;
    assetIds[1] = 1;

    assetAmounts = new uint256[](2);
    assetAmounts[0] = 1;
    assetAmounts[1] = 1;

    assetTypes = new uint256[](2);
    assetTypes[0] = 1;
    assetTypes[1] = 1;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test7_1_ERC1155() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](1);
    assetAddresses[0] = address(interleave);

    assetIds = new uint256[](1);
    assetIds[0] = 1;

    assetAmounts = new uint256[](1);
    assetAmounts[0] = 1;

    assetTypes = new uint256[](1);
    assetTypes[0] = 2;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test8_2_diff_ERC1155() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](2);
    assetAddresses[0] = address(interleave);
    assetAddresses[1] = address(genericStoreFront);

    assetIds = new uint256[](2);
    assetIds[0] = 1;
    assetIds[1] = 1;

    assetAmounts = new uint256[](2);
    assetAmounts[0] = 1;
    assetAmounts[1] = 1;

    assetTypes = new uint256[](2);
    assetTypes[0] = 2;
    assetTypes[1] = 2;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test9_1_ERC20_1_ERC721() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](2);
    assetAddresses[0] = address(link);
    assetAddresses[1] = address(bayc);

    assetIds = new uint256[](2);
    assetIds[0] = 1;
    assetIds[1] = 5;

    assetAmounts = new uint256[](2);
    assetAmounts[0] = 1000;
    assetAmounts[1] = 1;

    assetTypes = new uint256[](2);
    assetTypes[0] = 0;
    assetTypes[1] = 1;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test10_1_ERC20_2_same_ERC721() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](3);
    assetAddresses[0] = address(link);
    assetAddresses[1] = address(bayc);
    assetAddresses[2] = address(bayc);

    assetIds = new uint256[](3);
    assetIds[0] = 0;
    assetIds[1] = 6;
    assetIds[2] = 7;

    assetAmounts = new uint256[](3);
    assetAmounts[0] = 1000;
    assetAmounts[1] = 1;
    assetAmounts[2] = 1;

    assetTypes = new uint256[](3);
    assetTypes[0] = 0;
    assetTypes[1] = 1;
    assetTypes[2] = 1;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test11_1_ERC20_2_diff_ERC721() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](3);
    assetAddresses[0] = address(link);
    assetAddresses[1] = address(bayc);
    assetAddresses[2] = address(mayc);

    assetIds = new uint256[](3);
    assetIds[0] = 0;
    assetIds[1] = 8;
    assetIds[2] = 2;

    assetAmounts = new uint256[](3);
    assetAmounts[0] = 1000;
    assetAmounts[1] = 1;
    assetAmounts[2] = 1;

    assetTypes = new uint256[](3);
    assetTypes[0] = 0;
    assetTypes[1] = 1;
    assetTypes[2] = 1;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test12_2_ERC20_2_diff_ERC721() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](4);
    assetAddresses[0] = address(link);
    assetAddresses[1] = address(bayc);
    assetAddresses[2] = address(mayc);
    assetAddresses[3] = address(snx);

    assetIds = new uint256[](4);
    assetIds[0] = 0;
    assetIds[1] = 9;
    assetIds[2] = 3;
    assetIds[3] = 0;

    assetAmounts = new uint256[](4);
    assetAmounts[0] = 1000;
    assetAmounts[1] = 1;
    assetAmounts[2] = 1;
    assetAmounts[3] = 100;

    assetTypes = new uint256[](4);
    assetTypes[0] = 0;
    assetTypes[1] = 1;
    assetTypes[2] = 1;
    assetTypes[3] = 0;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test13_2_ERC20_2_same_ERC721_2_diff_ERC1155() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](6);
    assetAddresses[0] = address(link);
    assetAddresses[1] = address(bayc);
    assetAddresses[2] = address(bayc);
    assetAddresses[3] = address(interleave);
    assetAddresses[4] = address(genericStoreFront);
    assetAddresses[5] = address(snx);

    assetIds = new uint256[](6);
    assetIds[0] = 0;
    assetIds[1] = 10;
    assetIds[2] = 11;
    assetIds[3] = 1;
    assetIds[4] = 1;
    assetIds[5] = 1;

    assetAmounts = new uint256[](6);
    assetAmounts[0] = 1000;
    assetAmounts[1] = 1;
    assetAmounts[2] = 1;
    assetAmounts[3] = 10;
    assetAmounts[4] = 10;
    assetAmounts[5] = 100;

    assetTypes = new uint256[](6);
    assetTypes[0] = 0;
    assetTypes[1] = 1;
    assetTypes[2] = 1;
    assetTypes[3] = 2;
    assetTypes[4] = 2;
    assetTypes[5] = 0;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }

  function test14_2_ERC20_2_diff_ERC721_2_diff_ERC1155() public {
    address[] memory assetAddresses;
    uint256[] memory assetIds;
    uint256[] memory assetAmounts;
    uint256[] memory assetTypes;

    assetAddresses = new address[](6);
    assetAddresses[0] = address(link);
    assetAddresses[1] = address(bayc);
    assetAddresses[2] = address(mayc);
    assetAddresses[3] = address(interleave);
    assetAddresses[4] = address(genericStoreFront);
    assetAddresses[5] = address(snx);

    assetIds = new uint256[](6);
    assetIds[0] = 0;
    assetIds[1] = 12;
    assetIds[2] = 4;
    assetIds[3] = 1;
    assetIds[4] = 1;
    assetIds[5] = 1;

    assetAmounts = new uint256[](6);
    assetAmounts[0] = 1000;
    assetAmounts[1] = 1;
    assetAmounts[2] = 1;
    assetAmounts[3] = 10;
    assetAmounts[4] = 10;
    assetAmounts[5] = 100;

    assetTypes = new uint256[](6);
    assetTypes[0] = 0;
    assetTypes[1] = 1;
    assetTypes[2] = 1;
    assetTypes[3] = 2;
    assetTypes[4] = 2;
    assetTypes[5] = 0;

    proxy.deposit(assetAddresses, assetIds, assetAmounts, assetTypes);
  }


}
