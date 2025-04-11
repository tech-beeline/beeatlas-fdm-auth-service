package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.aspect.HeaderControl;
import ru.beeline.fdmauth.domain.Product;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.exception.EntityNotFoundException;
import ru.beeline.fdmauth.service.ProductService;
import ru.beeline.fdmauth.service.UserService;

import java.util.List;

import static ru.beeline.fdmauth.utils.Constant.USER_ID_HEADER;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api")
@Api(value = "Product API", tags = "Product")
public class ProductController {

    @Autowired
    private ProductService productService;

    @Autowired
    private UserService userService;


    @GetMapping(value = "/product/{id}/existence", produces = "application/json")
    @ApiOperation(value = "Проверка существования продукта", response = Boolean.class)
    public ResponseEntity<Boolean> checkProductExistence(@PathVariable Long id) {
        return ResponseEntity.ok(productService.checkProductExistenceById(id));
    }

    @GetMapping(value = "/user/{id}/product", produces = "application/json")
    @ApiOperation(value = "Получение списка продуктов пользователя", response = List.class)
    public ResponseEntity<List<Product>> getProducts(@PathVariable Integer id) {
            return ResponseEntity.ok(productService.findProductsByUser(userService.findUserById(id)));
    }


    @HeaderControl
    @GetMapping(value = "/admin/v1/product", produces = "application/json")
    @ApiOperation(value = "Получение списка продуктов пользователя", response = List.class)
    public ResponseEntity<List<Product>> getUserProducts(@RequestHeader(value = USER_ID_HEADER, required = false) String userId){
        UserProfile user = userService.findUserById(Integer.valueOf(userId));
            return ResponseEntity.ok(productService.findProductsByUser(user));
    }
}