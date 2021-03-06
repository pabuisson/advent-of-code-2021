# frozen_string_literal: true

require './advent_day.rb'

class Day16 < AdventDay
  def compute_part_1!
    packet = Packet.new(hexa: data.first)
    packet.self_and_subpackets.sum(&:version)
  end

  def compute_part_2!
    packet = Packet.new(hexa: data.first)
    packet.value
  end

  private

  class Packet
    attr_reader :hexa, :binary,
      :version, :type_id, :length_type_id,
      :value, :subpackets, :remaining_bits

    module TypeID
      SUM = 0
      PRODUCT = 1
      MINIMUM = 2
      MAXIMUM = 3
      LITERAL = 4
      GREATER_THAN = 5
      LESS_THAN = 6
      EQUAL_TO = 7
    end

    def initialize(hexa: nil, binary: nil)
      if hexa
        @hexa = hexa
        @binary = parse_hexa(hexa: hexa)
      elsif binary
        @binary = binary
        @hexa = parse_binary(binary: binary)
      else
        raise ArgumentError, 'Please provide either hexa: or binary: arguments'
      end

      @subpackets = []
      parse(binary: @binary)
    end

    BITS_FOR_NUMBER_OF_SUBPACKETS_BITS = 15
    BITS_FOR_NUMBER_OF_SUBPACKETS = 11

    def parse(binary:)
      binary_chars = binary.chars
      @version = binary_chars.shift(3).join('').to_i(2)
      @type_id = binary_chars.shift(3).join('').to_i(2)

      if @type_id == TypeID::LITERAL
        @value, @remaining_bits = parse_literal_value(binary: binary_chars.join(''))
      else
        @length_type_id = binary_chars.shift.to_i
        @subpackets, @remaining_bits = parse_operator(length_type_id: @length_type_id, binary: binary_chars.join(''))
      end
    end

    def self_and_subpackets
      [self] + @subpackets.flat_map(&:self_and_subpackets)
    end

    def value
      case @type_id
      when TypeID::LITERAL then @value
      when TypeID::SUM then subpackets.sum(&:value)
      when TypeID::PRODUCT then subpackets.map(&:value).reduce(:*)
      when TypeID::MINIMUM then subpackets.map(&:value).min
      when TypeID::MAXIMUM then subpackets.map(&:value).max
      when TypeID::GREATER_THAN then greater_than?
      when TypeID::LESS_THAN then less_than?
      when TypeID::EQUAL_TO then equality?
      end
    end

    private

    def parse_hexa(hexa:)
      expected_length = hexa.length * 4
      hexa.to_i(16).to_s(2).rjust(expected_length, '0')
    end

    def parse_binary(binary:)
      binary.to_i(2).to_s(16).upcase
    end

    def parse_operator(length_type_id:, binary:)
      if length_type_id.zero?
        parse_operator_type_zero(binary: binary)
      elsif length_type_id == 1
        parse_operator_type_one(binary: binary)
      end
    end

    def parse_operator_type_zero(binary:)
      binary_chars = binary.chars
      number_of_subpackets_bits = binary_chars.shift(BITS_FOR_NUMBER_OF_SUBPACKETS_BITS).join('').to_i(2)
      bits_to_consume = binary_chars.shift(number_of_subpackets_bits)

      subpackets = []
      while bits_to_consume.any?
        subpackets << Packet.new(binary: bits_to_consume.join(''))
        bits_to_consume = subpackets.last.remaining_bits.chars
      end

      [subpackets, binary_chars.join('')]
    end

    def parse_operator_type_one(binary:)
      binary_chars = binary.chars
      number_of_subpackets = binary_chars.shift(BITS_FOR_NUMBER_OF_SUBPACKETS).join('').to_i(2)

      subpackets = []
      while subpackets.size < number_of_subpackets
        subpackets << Packet.new(binary: binary_chars.join(''))
        binary_chars = subpackets.last.remaining_bits.chars
      end

      [subpackets, binary_chars.join('')]
    end

    LAST_VALUE_LEADING_CHAR = '0'

    def parse_literal_value(binary:)
      concatenated_values = []
      binary_chars = binary.chars
      loop do
        value = binary_chars.shift(5)

        first_char = value[0]
        concatenated_values += value[1..]

        break if first_char == LAST_VALUE_LEADING_CHAR
      end

      literal_value = concatenated_values.join('').to_i(2)
      remaining_bits = binary_chars.join('')
      [literal_value, remaining_bits]
    end

    def equality?
      return 0 unless subpackets.size == 2
      subpackets.first.value == subpackets.last.value ? 1 : 0
    end

    def greater_than?
      return 0 unless subpackets.size == 2
      subpackets.first.value > subpackets.last.value ? 1 : 0
    end

    def less_than?
      return 0 unless subpackets.size == 2
      subpackets.first.value < subpackets.last.value ? 1 : 0
    end
  end
end
