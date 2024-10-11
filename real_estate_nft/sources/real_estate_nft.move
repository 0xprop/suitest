module real_estate_nft::deed {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::package;
    use sui::display;
    use sui::event;
    use std::string::{Self, String};
    use std::vector;

    // Error codes
    const ENotOwner: u64 = 1;

    // Events
    public struct DeedMinted has copy, drop {
        deed_id: ID,
        owner: address,
        address: String,
    }

    public struct DeedTransferred has copy, drop {
        deed_id: ID,
        from: address,
        to: address,
    }

    public struct DeedUpdated has copy, drop {
        deed_id: ID,
        field: String,
        new_value: String,
    }

    public struct RealEstateDeed has key, store {
        id: UID,
        owner: address,
        address: vector<u8>,
        title_status: vector<u8>,
        property_value: u64,
    }

    public struct DEED has drop {}

    fun init(witness: DEED, ctx: &mut TxContext) {
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"description"),
            string::utf8(b"image_url"),
            string::utf8(b"address"),
            string::utf8(b"title_status"),
            string::utf8(b"property_value"),
        ];
        let values = vector[
            string::utf8(b"Real Estate Deed"),
            string::utf8(b"A digital representation of a real estate deed"),
            string::utf8(b"https://example.com/image.png"),
            string::utf8(b"{address}"),
            string::utf8(b"{title_status}"),
            string::utf8(b"{property_value}"),
        ];
        let publisher = package::claim(witness, ctx);
        let mut display = display::new_with_fields<RealEstateDeed>(
            &publisher, keys, values, ctx
        );
        display::update_version(&mut display);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    fun u64_to_string(mut value: u64): vector<u8> {
        if (value == 0) {
            return b"0"
        };
        let mut buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        buffer
    }

    public fun create_deed(
        owner: address,
        address: vector<u8>,
        title_status: vector<u8>,
        property_value: u64,
        ctx: &mut TxContext
    ): RealEstateDeed {
        RealEstateDeed {
            id: object::new(ctx),
            owner,
            address,
            title_status,
            property_value,
        }
    }

    public entry fun mint_deed(
        owner: address,
        address: vector<u8>,
        title_status: vector<u8>,
        property_value: u64,
        ctx: &mut TxContext
    ) {
        let deed = create_deed(owner, address, title_status, property_value, ctx);
        let deed_id = object::id(&deed);
        event::emit(DeedMinted {
            deed_id,
            owner,
            address: string::utf8(address),
        });
        transfer::transfer(deed, owner);
    }

    public entry fun transfer_deed(deed: &mut RealEstateDeed, recipient: address, ctx: &TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(sender == deed.owner, ENotOwner);
        let deed_id = object::id(deed);
        let old_owner = deed.owner;
        deed.owner = recipient;
        event::emit(DeedTransferred {
            deed_id,
            from: old_owner,
            to: recipient,
        });
    }

    public entry fun update_title_status(deed: &mut RealEstateDeed, new_status: vector<u8>, ctx: &TxContext) {
        assert!(tx_context::sender(ctx) == deed.owner, ENotOwner);
        let deed_id = object::id(deed);
        deed.title_status = new_status;
        event::emit(DeedUpdated {
            deed_id,
            field: string::utf8(b"title_status"),
            new_value: string::utf8(new_status),
        });
    }

    public entry fun update_property_value(deed: &mut RealEstateDeed, new_value: u64, ctx: &TxContext) {
        assert!(tx_context::sender(ctx) == deed.owner, ENotOwner);
        let deed_id = object::id(deed);
        deed.property_value = new_value;
        event::emit(DeedUpdated {
            deed_id,
            field: string::utf8(b"property_value"),
            new_value: string::utf8(u64_to_string(new_value)),
        });
    }

    public fun owner(deed: &RealEstateDeed): address {
        deed.owner
    }

    public fun deed_id(deed: &RealEstateDeed): ID {
        object::uid_to_inner(&deed.id)
    }
}