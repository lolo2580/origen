module Origen
  module PowerDomains
    class PowerDomain
      attr_accessor :id, :description, :voltage_range, :nominal_voltage, :setpoint

      def initialize(id, options = {}, &block)
        @id = id
        @description = ''
        @id = @id.symbolize unless @id.is_a? Symbol
        options.each { |k, v| instance_variable_set("@#{k}", v) }
        (block.arity < 1 ? (instance_eval(&block)) : block.call(self)) if block_given?
        fail unless attrs_ok?
      end

      def name
        @id
      end

      # Returns an Array of all pins that reference the power domain
      def pins
        signal_pins + ground_pins + power_pins
      end

      # Returns an Array of signal pin IDs that match the power domain ID
      def signal_pins
        Origen.top_level.pins.select { |_pin_id, p| p.supply == id }.keys
      end

      # Returns an Array of ground pin IDs that match the power domain ID
      def ground_pins
        Origen.top_level.ground_pins.select { |_pin_id, p| p.supply == id }.keys
      end

      # Returns an Array of ground pin IDs that match the power domain ID
      def power_pins
        Origen.top_level.power_pins.select { |_pin_id, p| p.supply == id }.keys
      end

      # Checks for the existence of a signal pin that references the power domain
      def has_signal_pin?(pin)
        signal_pins.include?(pin) ? true : false
      end

      # Checks for the existence of a signal pin that references the power domain
      def has_ground_pin?(pin)
        ground_pins.include?(pin) ? true : false
      end

      # Checks for the existence of a signal pin that references the power domain
      def has_power_pin?(pin)
        power_pins.include?(pin) ? true : false
      end

      # Checks if a pin references the power domain, regardless of type
      def has_pin?(pin)
        pins.include? pin
      end

      # Checks for a pin type, returns nil if it is not found
      def pin_type(pin)
        if self.has_pin?(pin) == false
          nil
        else
          [:signal, :ground, :power].each do |pintype|
            return pintype if send("has_#{pintype}_pin?", pin)
          end
        end
      end

      # Nominal voltage
      def nominal_voltage
        @nominal_voltage
      end
      alias_method :nominal, :nominal_voltage
      alias_method :nom, :nominal_voltage

      # Current setpoint, defaults top nil on init
      def setpoint
        @setpoint
      end
      alias_method :curr_value, :setpoint
      alias_method :value, :setpoint

      # Acceptable voltage range
      def voltage_range
        @voltage_range
      end
      alias_method :range, :voltage_range

      # Setter for setpoint
      def setpoint=(val)
        unless setpoint_ok?(val)
          Origen.log.warn("Setpoint (#{setpoint_string(val)}) for power domain '#{name}' is not within the voltage range (#{voltage_range_string})!")
        end
        @setpoint = val
      end

      # Checks if the setpoint is valid
      def setpoint_ok?(val = nil)
        if val.nil?
          voltage_range.include?(setpoint) ? true : false
        else
          voltage_range.include?(val) ? true : false
        end
      end
      alias_method :value_ok?, :setpoint_ok?
      alias_method :val_ok?, :setpoint_ok?

      def method_missing(m, *args, &block)
        ivar = "@#{m.to_s.gsub('=', '')}"
        ivar_sym = ":#{ivar}"
        if m.to_s =~ /=$/
          define_singleton_method(m) do |val|
            instance_variable_set(ivar, val)
          end
        elsif instance_variables.include? ivar_sym
          instance_variable_get(ivar)
        else
          define_singleton_method(m) do
            instance_variable_get(ivar)
          end
        end
        send(m, *args, &block)
      end

      private

      def attrs_ok?
        return_value = true
        unless description.is_a? String
          Origen.log.error("Power domain attribute 'description' must be a String!")
          return_value = false
        end
        return_value = false unless voltages_ok?
        return_value
      end

      def setpoint_string(val = nil)
        if val.nil?
          setpoint.as_units('V')
        else
          val.as_units('V')
        end
      end

      def voltages_ok?
        if nominal_voltage.nil?
          false
        elsif voltage_range.nil?
          Origen.log.error("PPEKit: Missing voltage range for power domain '#{name}'!")
          false
        elsif voltage_range.is_a? Range
          if voltage_range.include?(nominal_voltage)
            true
          else
            Origen.log.error("PPEKit: Nominal voltage #{nominal_voltage} is not inbetween the voltage range #{voltage_range} for power domain '#{name}'!")
            false
          end
        else
          Origen.log.error("Power domain attribute 'voltage_range' must be a Range!")
          return_value = false
        end
      end
    end
  end
end
