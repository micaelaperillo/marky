CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_sub TEXT NOT NULL,
  name TEXT NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  frequency_min INTEGER NOT NULL DEFAULT 60,
  topics TEXT[] NOT NULL,

  CONSTRAINT campaigns_user_name_unique UNIQUE (user_sub, name)
);