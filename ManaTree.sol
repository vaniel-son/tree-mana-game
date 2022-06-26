// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Helper we wrote to encode in Base64
import "./libraries/Base64.sol";

import "hardhat/console.sol";

// Our contract inherits from ERC721, which is the standard NFT contract!
contract ManaTree is ERC721 {

  struct DojoAvatarAttributes {
    uint characterIndex;
    string name;
    string imageURI;    
    uint hasWorkout;    
  }

  // The tokenId is the NFTs unique identifier, it's just a number that goes
  // 0, 1, 2, 3, etc.
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // array holding all the default characters (only 1 type for now)
  DojoAvatarAttributes[] defaultCharacters;

  // We create a mapping from the nft's tokenId => that NFTs attributes.
  mapping(uint256 => DojoAvatarAttributes) public nftHolderAttributes;

  struct TheTree {
    string name;
    string imageURI;
    uint level;
  }

  TheTree public manaTree;

  // A mapping from an address => the NFTs tokenId. Gives me an ez way
  // to store the owner of the NFT and reference it later.
  mapping(address => uint256) public nftHolders;

  event DojoAvatarNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event WateringComplete(address sender);

  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory hasWorkout,
    string memory treeName, 
    string memory treeImageURI,
    uint treeLevel
  )
    ERC721("DojoHealthAvatar", "DOJO")
  {
    // Initialize the tree. Save it to our global "manaTree" state variable.
    manaTree = TheTree({
      name: treeName,
      imageURI: treeImageURI,
      level: treeLevel
    });

    console.log("Done initializing tree %s w/ img %s", manaTree.name, manaTree.imageURI);
    
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(DojoAvatarAttributes({
        characterIndex: i,
        name: characterNames[i],
        imageURI: characterImageURIs[i],
        hasWorkout: hasWorkout[i]
      }));

      DojoAvatarAttributes memory c = defaultCharacters[i];
      
      console.log("Done initializing %s w/ img %s", c.name, c.imageURI);
    }

    // I increment _tokenIds here so that my first NFT has an ID of 1.
    _tokenIds.increment();
  }

  function mintCharacterNFT() external {
    // Get current tokenId (starts at 1).
    uint256 newItemId = _tokenIds.current();

    // assign tokenId to the caller's wallet address.
    _safeMint(msg.sender, newItemId);

    // map the tokenId => their character attributes
    nftHolderAttributes[newItemId] = DojoAvatarAttributes({
      characterIndex: 0,
      name: defaultCharacters[0].name,
      imageURI: defaultCharacters[0].imageURI,
      hasWorkout: defaultCharacters[0].hasWorkout
    });

    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, 0);
    
    // Manage who owns which NFT token ID
    nftHolders[msg.sender] = newItemId;

    // Increment the tokenId for the next person that uses it.
    _tokenIds.increment();

    emit DojoAvatarNFTMinted(msg.sender, newItemId, 0);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    DojoAvatarAttributes memory charAttributes = nftHolderAttributes[_tokenId];

    string memory hasWorkout = Strings.toString(charAttributes.hasWorkout);

    string memory json = Base64.encode(
        abi.encodePacked(
        '{"name": "',
        charAttributes.name,
        ' -- NFT #: ',
        Strings.toString(_tokenId),
        '", "description": "This is a Dojo health avatar than can be used in any ecosystem to provide rewards to you because you are healthy!", "image": "ipfs://',
        charAttributes.imageURI,
        '", "attributes": [ { "trait_type": "Health status", "value": ',
        hasWorkout,'} ]}'
        )
    );

    string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
  );
  
  return output;
  }

  function waterTree() public {
    // Get the state of the player's NFT.
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
    DojoAvatarAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
    console.log("\nPlayer w/ character %s about to water the tree.", player.name);
    console.log("Tree %s has been watered.", manaTree.name);

    require (
      player.hasWorkout > 0,
      "Error: character needs to workout so they can water the tree."
    );

    console.log("Old Dojo character hasWorkout %s", player.hasWorkout);
    console.log("Old Mana Tree level %s", manaTree.level);
    console.log("Old Mana Tree image %s", manaTree.imageURI);

    // Update tree level
    manaTree.level = manaTree.level + 1; 

    // Update tree image
    if (manaTree.level > 2) {
        manaTree.imageURI = "https://cloudflare-ipfs.com/ipfs/Qmemut53iXwmgNPJUeVgkhkwspLHYunkkfCazYRpiFryHr";
    } else {
        manaTree.imageURI = "https://cloudflare-ipfs.com/ipfs/QmRia9heXepy5tjd8WgQ8fPByBmKqP87AvSR5jrhz5hYZt";
    }

    // Reduce dojo avatar hasWorkout to 0, which indicates they haven't worked out since the last watering
    player.hasWorkout = 0;

    // console stuff
    console.log("New Dojo character hasWorkout %s", player.hasWorkout);
    console.log("New Mana Tree level %s", manaTree.level);
    console.log("New Mana Tree image %s", manaTree.imageURI);

    emit WateringComplete(msg.sender);
  }

  function checkIfUserHasNFT() public view returns (DojoAvatarAttributes memory) {
    // Get the tokenId of the user's character NFT
    uint256 userNftTokenId = nftHolders[msg.sender];

    // If the user has a tokenId in the map, return their Dojo avatar.
    if (userNftTokenId > 0) {
      return nftHolderAttributes[userNftTokenId];
    }
    // Else, return an empty Dojo avatar.
    else {
      DojoAvatarAttributes memory emptyStruct;
      return emptyStruct;
    }
  }

  function getAllDefaultCharacters() public view returns (DojoAvatarAttributes[] memory) {
    return defaultCharacters;
  }

  function getManaTree() public view returns (TheTree memory) {
    return manaTree;
  }

  function updateUserWorkoutStatus() public {
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
    DojoAvatarAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
    console.log("Old Dojo character hasWorkout %s", player.hasWorkout);
    player.hasWorkout = 1;
    console.log("New Dojo character hasWorkout %s", player.hasWorkout);
  }
}
