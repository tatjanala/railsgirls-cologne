require_lib 'events/geocode_address'

class Event < ActiveRecord::Base
  ATTRIBUTES = [ :title,
                 :description,
                 :city_id,
                 :city,
                 :coordinates,
                 :starts_on,
                 :ends_on,
                 :registration_deadline,
                 :active]

  attr_accessible *ATTRIBUTES

  validates :description, :city_id, :starts_on, :ends_on, presence: true
  validates :active, uniqueness: {scope: :city_id}, if: :active?

  delegate :name, to: :city, prefix: true
  
  delegate :address_line_1, :address_line_2, :address_postcode, :address_city, to: :host
  
  delegate :name, to: :host, prefix: true

  belongs_to :city
  has_many :registrations

  has_many :event_sponsorships
  has_many :sponsors, through: :event_sponsorships

  has_many :event_coachings
  has_many :coaches, through: :event_coachings

  delegate :address_line_1, :address_line_2, :address_postcode, :address_city, to: :host
  delegate :name, :website, :image_url, :description, to: :host, prefix: true

  def title
    "#{self.starts_on.strftime("%d")}-#{self.ends_on.strftime("%d")} #{self.starts_on.strftime("%B %Y")}"
  end
  
  def accepting_registrations?
    return true if registration_deadline.present?
  end

  def registrations_open?
    accepting_registrations? and Date.today <= registration_deadline
  end

  def host
    event_sponsorship = event_sponsorships.where(host: true).first

    event_sponsorship.present? and return event_sponsorship.sponsor
  end

  def non_hosting_sponsors
    sponsors - [host]
  end

  def has_host?
    host.present?
  end

  def dates
    return format_date(starts_on) if starts_on.eql? ends_on
    dates = day(starts_on)
    dates << month(starts_on) unless starts_on.month.eql? ends_on.month
    dates << until_day_month_and_year(ends_on)
  end

  def export_applications_to_trello
    EventTrello.new(self).export
  end

  private

  def format_date date
    return date.strftime("%B %-d, %Y")
  end

  def day date
    date.strftime("%-d")
  end

  def month date
    date.strftime(" %B")
  end

  def until_day_month_and_year date
    date.strftime("-%-d %B %Y")
  end

  def address=(address)
    super address

    # cache the coordinates of the location for showing on a map
    self.coordinates = Events::GeocodeAddress.to_coordinates(address)
  end

end
