# frozen_string_literal: true

class TransferNode < ApplicationRecord
  has_many :transfer_edges
end