{
    outputs = { self }: {
        a = 1;
        b = self.a + 1;
    };
}
