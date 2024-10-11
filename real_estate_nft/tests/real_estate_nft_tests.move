#[test_only]
module real_estate_nft::deed_tests {
    use sui::test_scenario::{Self, Scenario};
    use real_estate_nft::deed::{Self, RealEstateDeed};

    #[test]
    fun test_mint_deed() {
        let owner = @0xCAFE;
        let mut scenario = test_scenario::begin(owner);
        test_mint_deed_scenario(&mut scenario);
        test_scenario::end(scenario);
    }

    fun test_mint_deed_scenario(scenario: &mut Scenario) {
        let owner = @0xCAFE;
        test_scenario::next_tx(scenario, owner);
        {
            let ctx = test_scenario::ctx(scenario);
            deed::mint_deed(owner, b"123 Main St", b"Clear", 100000, ctx);
        };
        test_scenario::next_tx(scenario, owner);
        {
            let deed = test_scenario::take_from_sender<RealEstateDeed>(scenario);
            assert!(deed::owner(&deed) == owner, 0);
            test_scenario::return_to_sender(scenario, deed);
        };
    }

    #[test]
    fun test_transfer_deed() {
        let owner = @0xCAFE;
        let recipient = @0xDEAD;
        let mut scenario = test_scenario::begin(owner);
        test_mint_deed_scenario(&mut scenario);
        test_scenario::next_tx(&mut scenario, owner);
        {
            let mut deed = test_scenario::take_from_sender<RealEstateDeed>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            deed::transfer_deed(&mut deed, recipient, ctx);
            assert!(deed::owner(&deed) == recipient, 0);
            test_scenario::return_to_sender(&scenario, deed);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = deed::ENotOwner)]
    fun test_transfer_deed_not_owner() {
        let owner = @0xCAFE;
        let not_owner = @0xBABE;
        let recipient = @0xDEAD;
        let mut scenario = test_scenario::begin(owner);
        
        // Mint the deed
        test_mint_deed_scenario(&mut scenario);
        
        // Switch to the non-owner's context
        test_scenario::next_tx(&mut scenario, not_owner);
        {
            // Try to take the deed from the owner's inventory, not the non-owner's
            let mut deed = test_scenario::take_from_address<RealEstateDeed>(&scenario, owner);
            let ctx = test_scenario::ctx(&mut scenario);
            
            // This should fail because not_owner is not the owner of the deed
            deed::transfer_deed(&mut deed, recipient, ctx);
            
            // Return the deed to the owner's inventory
            test_scenario::return_to_address(owner, deed);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_title_status() {
        let owner = @0xCAFE;
        let mut scenario = test_scenario::begin(owner);
        test_mint_deed_scenario(&mut scenario);
        test_scenario::next_tx(&mut scenario, owner);
        {
            let mut deed = test_scenario::take_from_sender<RealEstateDeed>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            deed::update_title_status(&mut deed, b"Encumbered", ctx);
            test_scenario::return_to_sender(&scenario, deed);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_property_value() {
        let owner = @0xCAFE;
        let mut scenario = test_scenario::begin(owner);
        test_mint_deed_scenario(&mut scenario);
        test_scenario::next_tx(&mut scenario, owner);
        {
            let mut deed = test_scenario::take_from_sender<RealEstateDeed>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            deed::update_property_value(&mut deed, 150000, ctx);
            test_scenario::return_to_sender(&scenario, deed);
        };
        test_scenario::end(scenario);
    }
}
