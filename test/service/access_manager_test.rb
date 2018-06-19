require './test/test_helper'

class AccessManagerTest < ActiveSupport::TestCase
  test 'access manager should give access to valid cards if the assigned user is enabled and has permission for given lock and log the access' do
    card_number = 'AABBCCDD'
    lock_name = 'Main door'
    direction = 'enter'
    normal_user_role = Role.create!(name: 'Normal user')
    user = User.create!(name: 'test user', roles: [normal_user_role], enabled: true,)
    Card.create!(card_number: card_number, user: user)
    main_door_lock = Lock.create!(name: lock_name)
    Permission.create!(role: normal_user_role, lock: main_door_lock)

    assert_equal(true, AccessManager.new(card_number, lock_name, direction).process)
    assert_equal(1, AccessLog.where({user_id: user.id, card_number: card_number, lock_id: main_door_lock.id, direction: direction, access_provided: true}).size)
  end

  test 'access manager should deny access to invalid cards and log the attempt' do
    card_number = 'INVALID'
    direction = 'enter'
    actual = AccessManager.new(card_number, Lock.first.name, direction).process

    assert_equal(false, actual)
    assert_equal(1, AccessLog.where({card_number: card_number, lock_id: Lock.first.id, direction: direction, access_provided: false}).size)
  end

  test 'access manager should deny access to unassigned cards and log the attempt' do
    card_number = 'AABBCCDD'
    direction = 'enter'
    Card.create!(card_number: card_number)

    assert_equal(false, AccessManager.new(card_number, Lock.first.name, direction).process)
    assert_equal(1, AccessLog.where({card_number: card_number, lock_id: Lock.first.id, direction: direction, access_provided: false}).size)
  end

  test 'access manager should deny access to unknown lock and dont log the attempt' do
    card_number = 'AABBCCDD'
    user = User.create!(name: 'test user', enabled: true)
    invalid_lock_id = 110011001100
    direction = 'enter'
    Card.create!(card_number: card_number, user: user)

    assert_equal(false, AccessManager.new(card_number, 'invalid lock', direction).process)
    assert_equal(0, AccessLog.where({card_number: card_number, lock_id: invalid_lock_id, direction: direction, access_provided: false}).size)
  end

  test 'access manager should deny access to valid cards if the assigned user is enabled but dont have permission for given door and log the attempt' do
    card_number = 'AABBCCDD'
    lock_name = 'Main door'
    direction = 'enter'
    user = User.create!(name: 'test user', enabled: true)
    Card.create!(card_number: card_number, user: user)
    Lock.create!(name: lock_name)
    Role.create!(name: 'Normal user')

    assert_equal(false, AccessManager.new(card_number, Lock.first.name, direction).process)
    assert_equal(1, AccessLog.where({card_number: card_number, lock_id: Lock.first.id, direction: direction, access_provided: false}).size)
  end

  test 'access manager should deny access to valid cards if the assigned user have permission for given door but is disabled and log the attempt' do
    card_number = 'AABBCCDD'
    lock_name = 'Main door'
    direction = 'enter'
    user = User.create!(name: 'test user', enabled: false)
    Card.create!(card_number: card_number, user: user)
    main_door_lock = Lock.create!(name: lock_name)
    normal_user_role = Role.create!(name: 'Normal user')
    Permission.create!(role: normal_user_role, lock: main_door_lock)

    assert_equal(false, AccessManager.new(card_number, main_door_lock.name, direction).process)
    assert_equal(1, AccessLog.where({card_number: card_number, lock_id: main_door_lock.id, direction: direction, access_provided: false}).size)
  end

end
