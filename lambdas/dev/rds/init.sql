CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_sub TEXT NOT NULL,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  topics TEXT[] NOT NULL,

  CONSTRAINT campaigns_user_name_unique UNIQUE (user_sub, name)
);