# frozen_string_literal: true

json.success(@handler.success)
json.error(@handler.error)
json.errors(@handler.errors.details[:base])
json.successful(@handler.successful?)
json.status_code(@handler.status_code)
