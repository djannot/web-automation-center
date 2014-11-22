# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20131003190457) do

  create_table "clouds", force: true do |t|
    t.string   "api"
    t.string   "url"
    t.string   "ip_addresses"
    t.integer  "port"
    t.string   "token"
    t.string   "shared_secret"
    t.string   "bucket"
    t.integer  "user_id"
    t.integer  "platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "demos", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favorites", force: true do |t|
    t.text     "description"
    t.string   "http_method"
    t.string   "path_or_url"
    t.text     "headers"
    t.text     "body"
    t.string   "api"
    t.string   "api_type"
    t.string   "privilege"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "platforms", force: true do |t|
    t.string   "platform_type"
    t.string   "ip"
    t.string   "sys_admin"
    t.string   "sys_admin_password"
    t.string   "tenant_name"
    t.string   "tenant_admin"
    t.string   "tenant_admin_password"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "regexpressions", force: true do |t|
    t.string   "name"
    t.string   "expression"
    t.text     "description"
    t.integer  "task_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "demo_id"
    t.integer  "cloud_id"
    t.integer  "platform_id"
    t.integer  "favorite_id"
    t.integer  "position"
    t.integer  "user_id"
    t.string   "response_codes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email"
    t.string   "password_hash"
    t.string   "password_salt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
