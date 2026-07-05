class Api::V1::Accounts::Nexus::ReportsController < Api::V1::Accounts::Nexus::BaseController
  def sales
    require_sales_module!

    orders = Current.account.nexus_orders.includes(:nexus_order_items)

    render json: {
      summary: {
        total_orders: orders.count,
        total_revenue: orders.where(status: :completed).sum(:total).to_f,
        pending: orders.pending.count,
        confirmed: orders.confirmed.count,
        completed: orders.completed.count,
        cancelled: orders.cancelled.count
      },
      revenue_by_day: orders.where(status: :completed)
                            .group_by_day(:created_at, last: 30, format: '%Y-%m-%d')
                            .sum(:total)
                            .transform_values(&:to_f),
      orders_by_day: orders.group_by_day(:created_at, last: 30, format: '%Y-%m-%d').count,
      top_products: Current.account.nexus_order_items
                           .joins(:nexus_product)
                           .group('nexus_products.name')
                           .order('sum_quantity DESC')
                           .limit(5)
                           .sum(:quantity)
    }
  end

  def scheduling
    require_scheduling_module!

    appointments = Current.account.nexus_appointments.includes(:nexus_service, :nexus_time_slot)

    upcoming = appointments.joins(:nexus_time_slot)
                           .where('nexus_time_slots.start_time > ?', Time.current)
                           .where(status: [NexusAppointment.statuses[:pending], NexusAppointment.statuses[:confirmed]])

    render json: {
      summary: {
        total: appointments.count,
        pending: appointments.pending.count,
        confirmed: appointments.confirmed.count,
        completed: appointments.completed.count,
        cancelled: appointments.cancelled.count,
        upcoming: upcoming.count
      },
      by_service: appointments.joins(:nexus_service)
                              .group('nexus_services.name')
                              .count,
      appointments_by_day: appointments.joins(:nexus_time_slot)
                                       .where('nexus_time_slots.start_time >= ?', 30.days.ago)
                                       .group_by_day('nexus_time_slots.start_time', format: '%Y-%m-%d')
                                       .count
    }
  end
end
