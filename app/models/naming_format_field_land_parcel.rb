# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: naming_format_fields
#
#  created_at       :datetime
#  creator_id       :integer
#  field_name       :string           not null
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  naming_format_id :integer
#  position         :integer
#  type             :string           not null
#  updated_at       :datetime
#  updater_id       :integer
#
class NamingFormatFieldLandParcel < NamingFormatField
  enumerize :field_name, in: %i[cultivable_zone_name cultivable_zone_code activity campaign season production_mode free_field], default: :cultivable_zone_name
end
