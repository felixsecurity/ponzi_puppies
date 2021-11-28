# ponzi_puppies

Ponzi Puppies is an experimental NFT project that explores many unique aspects:


## Metadata
- Metadata is completely on chain an consists of a name and colorschema (uint256-encoded)
- Metadata can be determined by the user during minting
- Uniqueness of user-generated metadata is enforced within the contract
- Metadata can be rendered into an svg of a Puppy with a suitable off-chain backend

## Royalties
- Royalties are distributed to the first 10 owners of each NFT according to the formula 0.025/2**i for owner i.
- Royalties for each sale are enforced within the contract, which contains all payment logic

## Minting
- The minting function is a bonding curve in both time and quantity. The price is raised by 10% every 18.2 hours and by 1% after each minted item

## No Regular Transfers
- Formal compliance with the ERC721 standard ist kept, while the semantics are intentionally broken to achieve the custom payment logic and royalties enforcement

# Note
Ponzi Puppies is a project in the area of creative exploration. It should not be used as a building block for "regular" NFT projects, as many functionality that is commonly expected, such as compatibility with market places like OpenSea or even regular non-commercial transfer between addresses is intentionally removed to explore aggressive on-chain royalty enforcement.